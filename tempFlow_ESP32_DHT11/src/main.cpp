#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/semphr.h>
#include <freertos/queue.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <string>

//=============== CONFIGURATION ===============//
// Broches matérielles
#define LM35_PIN 34        // Capteur de température
#define LED_ROUGE_PIN 33   // LED d'alerte température haute
#define LED_VERTE_PIN 25   // LED température normale
#define SEUIL_TEMPERATURE 30.0  // Seuil d'alerte en °C

// Configuration ADC
#define ADC_REFERENCE_VOLTAGE 3.3
#define ADC_RESOLUTION 12
#define ADC_MAX_VALUE (1 << ADC_RESOLUTION)
#define SAMPLES_NUMBER 10   // Nombre d'échantillons pour la moyenne

// UUIDs des services BLE
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TEMPERATURE_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define BATTERY_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a9"

// Configuration BLE
#define MIN_CONNECTION_INTERVAL 24  // 24 * 1.25ms = 30ms
#define MAX_CONNECTION_INTERVAL 40  // 40 * 1.25ms = 50ms
#define SLAVE_LATENCY 0
#define SUPERVISION_TIMEOUT 400     // 400 * 10ms = 4s

// Structure de données pour la communication entre tâches
struct SensorData {
    float temperature;     // Température en °C
    uint8_t batteryLevel; // Niveau batterie 0-100%
};

//=============== VARIABLES GLOBALES ===============//
// Variables BLE
BLEServer *pServer = NULL;
BLECharacteristic *pTemperatureCharacteristic = NULL;  // UUID: 0x2A1C - Format: SINT16 (0.01 °C)
BLECharacteristic *pBatteryCharacteristic = NULL;      // UUID: 0x2A19 - Format: UINT8 (0-100%)
bool deviceConnected = false;
const uint8_t BATTERY_LEVEL = 83;  // Niveau de batterie fixe à 83%

// Ressources FreeRTOS
TaskHandle_t tempTaskHandle = NULL;    // Tâche lecture température
TaskHandle_t bleTaskHandle = NULL;     // Tâche envoi BLE
QueueHandle_t xSensorQueue;           // Queue pour les données des capteurs
SemaphoreHandle_t xSerialSemaphore;   // Sémaphore pour accès série

//=============== PROTOTYPES ===============//
void TaskLireTemperature(void *pvParameters);
void TaskEnvoiBLE(void *pvParameters);

//=============== CALLBACKS BLE ===============//
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        // LED verte allumée quand connecté
        digitalWrite(LED_ROUGE_PIN, LOW);
        digitalWrite(LED_VERTE_PIN, HIGH);
        
        // Configuration des paramètres de connexion pour plus de stabilité
        pServer->getConnId();
        esp_ble_conn_update_params_t connParams;
        connParams.min_int = MIN_CONNECTION_INTERVAL;
        connParams.max_int = MAX_CONNECTION_INTERVAL;
        connParams.latency = SLAVE_LATENCY;
        connParams.timeout = SUPERVISION_TIMEOUT;
        esp_ble_gap_update_conn_params(&connParams);
        
        // Création des tâches au moment de la connexion
        xTaskCreate(TaskLireTemperature, "Temp", 2048, NULL, 1, &tempTaskHandle);
        xTaskCreate(TaskEnvoiBLE, "BLE", 2048, NULL, 2, &bleTaskHandle);
        
        Serial.println("\n========================================");
        Serial.println("Appareil Bluetooth connecté!");
        Serial.println("Démarrage des tâches de mesure...");
        Serial.println("LED VERTE: Allumée - Appareil connecté");
        Serial.println("========================================\n");
    }

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        // LED rouge allumée quand déconnecté
        digitalWrite(LED_ROUGE_PIN, HIGH);
        digitalWrite(LED_VERTE_PIN, LOW);
        
        // Nettoyage des tâches à la déconnexion
        if (tempTaskHandle) { vTaskDelete(tempTaskHandle); tempTaskHandle = NULL; }
        if (bleTaskHandle) { vTaskDelete(bleTaskHandle); bleTaskHandle = NULL; }
        xQueueReset(xSensorQueue);
        
        Serial.println("\n========================================");
        Serial.println("Appareil Bluetooth déconnecté!");
        Serial.println("Arrêt des tâches de mesure...");
        Serial.println("LED ROUGE: Allumée - En attente de connexion");
        Serial.println("========================================\n");
        
        // Redémarrage de l'advertising après un court délai
        delay(500);
        BLEDevice::startAdvertising();
    }
};

//=============== TÂCHES FREERTOS ===============//
// Tâche de lecture de température et contrôle des LEDs
void TaskLireTemperature(void *pvParameters) {
    struct SensorData data;
    TickType_t xLastWakeTime = xTaskGetTickCount();
    
    while(true) {
        if (deviceConnected) {
            // Lecture ADC avec moyenne
            float rawValue = 0;
            for(int i = 0; i < SAMPLES_NUMBER; i++) {
                rawValue += analogRead(LM35_PIN);
                delay(1);  // Court délai entre les lectures
            }
            rawValue /= SAMPLES_NUMBER;
            
            // Conversion en tension (V) puis en température (°C)
            // Le LM35 donne 10mV/°C, donc 0.01V/°C
            float voltage = (rawValue * ADC_REFERENCE_VOLTAGE) / ADC_MAX_VALUE;
            data.temperature = voltage * 100.0;
            data.batteryLevel = BATTERY_LEVEL;
            
            // Debug détaillé
            Serial.printf("Raw ADC (moyenne): %.1f, Voltage: %.3fV, Température: %.2f°C\n", 
                        rawValue, voltage, data.temperature);
            
            // Contrôle des LEDs selon le seuil
            digitalWrite(LED_ROUGE_PIN, data.temperature > SEUIL_TEMPERATURE);
            digitalWrite(LED_VERTE_PIN, data.temperature <= SEUIL_TEMPERATURE);
            
            // Envoi des données à la tâche BLE via la queue
            xQueueSend(xSensorQueue, &data, 0);
            Serial.printf("Température: %.2f°C\n", data.temperature);
        }
        vTaskDelayUntil(&xLastWakeTime, pdMS_TO_TICKS(2000));  // Lecture toutes les 2 secondes
    }
}

// Tâche d'envoi des données via BLE
void TaskEnvoiBLE(void *pvParameters) {
    struct SensorData data;
    
    while(true) {
        if (deviceConnected && xQueueReceive(xSensorQueue, &data, pdMS_TO_TICKS(100)) == pdTRUE) {
            // Conversion de la température en int16 (x100 pour garder 2 décimales)
            int16_t tempValue = (int16_t)(data.temperature * 100);
            uint8_t tempBytes[2];
            tempBytes[0] = tempValue & 0xFF;         // LSB
            tempBytes[1] = (tempValue >> 8) & 0xFF;  // MSB
            
            // Envoi de la température en format SINT16
            pTemperatureCharacteristic->setValue(tempBytes, 2);
            pTemperatureCharacteristic->notify();
            
            // Envoi du niveau de batterie en format UINT8
            uint8_t batteryValue = data.batteryLevel;
            pBatteryCharacteristic->setValue(&batteryValue, 1);
            pBatteryCharacteristic->notify();
            
            Serial.printf("Envoi BLE - T:%.2f°C (raw:%d), B:%d%%\n", 
                        data.temperature, tempValue, batteryValue);
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

//=============== INITIALISATION ===============//
void setup() {
    Serial.begin(115200);
    
    // Configuration de l'ADC
    analogReadResolution(ADC_RESOLUTION);
    analogSetAttenuation(ADC_11db);
    
    pinMode(LED_ROUGE_PIN, OUTPUT);
    pinMode(LED_VERTE_PIN, OUTPUT);

    // LED rouge allumée au démarrage (non connecté)
    digitalWrite(LED_ROUGE_PIN, HIGH);
    digitalWrite(LED_VERTE_PIN, LOW);

    // Création des ressources FreeRTOS
    xSerialSemaphore = xSemaphoreCreateBinary();
    xSemaphoreGive(xSerialSemaphore);
    xSensorQueue = xQueueCreate(5, sizeof(struct SensorData));

    // Configuration du serveur BLE
    BLEDevice::init("ESP32_TempSensor");
    esp_ble_tx_power_set(ESP_BLE_PWR_TYPE_DEFAULT, ESP_PWR_LVL_P9);
    
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // Service principal
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Caractéristique de température (SINT16, 0.01°C)
    pTemperatureCharacteristic = pService->createCharacteristic(
        TEMPERATURE_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pTemperatureCharacteristic->addDescriptor(new BLE2902());

    // Caractéristique de batterie (UINT8, 0-100%)
    pBatteryCharacteristic = pService->createCharacteristic(
        BATTERY_CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    pBatteryCharacteristic->addDescriptor(new BLE2902());

    // Démarrage du service
    pService->start();

    // Configuration et démarrage de l'advertising
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // Fonctions pour aider avec iPhone, beaucoup d'appareils Android l'ignorent
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    Serial.println("BLE prêt - En attente de connexion...");
}

//=============== BOUCLE PRINCIPALE ===============//
void loop() {
    vTaskDelay(1000);  // Tâches gérées par FreeRTOS
}