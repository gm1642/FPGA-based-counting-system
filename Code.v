#include <SoftwareSerial.h>
#include <Adafruit_Fingerprint.h>

SoftwareSerial SIM900A(10, 11);

Adafruit_Fingerprint finger = Adafruit_Fingerprint(&SIM900A);

const int maxEnrollments = 5; // Maximum number of enrollments
int numEnrollments = 0; // Number of enrolled fingerprints

const int numPhoneNumbers = 2; // Define the number of phone numbers
String phoneNumbers[numPhoneNumbers] = {"+916397653492"};

void setup() {
  SIM900A.begin(9600);
  Serial.begin(9600);
  Serial.println("Text Message Module Ready & Verified");
  randomSeed(analogRead(0)); // Initialize random number generator
  delay(1000);
  Serial.println("Press 'e' to enroll fingerprints and 's' to send OTPs");

  // Initialize the fingerprint sensor
  finger.begin(57600);
  if (!finger.verifyPassword()) {
    Serial.println("Fingerprint sensor verification failed. Please check wiring.");
    while (1);
  }
  Serial.println("Fingerprint sensor initialized.");
}

void loop() {
  if (Serial.available() > 0) {
    char input = Serial.read();
    if (input == 'e') {
      enrollFingerprints();
    } else if (input == 's') {
      sendOtpToMultipleNumbers();
    }
  }

  if (SIM900A.available() > 0) {
    Serial.write(SIM900A.read());
  }
}

void enrollFingerprints() {
  Serial.println("Place your finger on the sensor for enrollment.");
  Serial.println("Remove your finger when prompted.");

  while (numEnrollments < maxEnrollments) {
    uint8_t id;

    if (finger.getImage() != FINGERPRINT_OK) {
      continue;
    }

    if (finger.image2Tz(1) != FINGERPRINT_OK) {
      continue;
    }

    if (finger.createModel() != FINGERPRINT_OK) {
      continue;
    }

    id = finger.storeModel(1);

    if (id != FINGERPRINT_OK) {
      Serial.print("Fingerprint enrolled with ID: ");
      Serial.println(id);
      numEnrollments++;
    } else {
      Serial.println("Fingerprint enrollment failed. Try again.");
    }
  }

  Serial.println("Fingerprint enrollment complete.");
}
void sendOtpToMultipleNumbers() {
  if (verifyFingerprint()) {
    for (int i = 0; i < numPhoneNumbers; i++) {
      String smsText = generateOTP(); // Generate a 6-digit OTP

      Serial.print("Sending OTP to: ");
      Serial.println(phoneNumbers[i]);

      SIM900A.println("AT+CMGF=1"); // Text Mode initialization
      delay(1000);
      SIM900A.print("AT+CMGS=\"");
      SIM900A.print(phoneNumbers[i]);
      SIM900A.println("\"");
      delay(1000);
      SIM900A.println(smsText); // Message content
      delay(100);
      SIM900A.write(26);
      delay(1000);
      Serial.println("Message sent successfully");
    }
  } else {
    Serial.println("Fingerprint verification failed.");
  }
}

String generateOTP() {
  // Generate a random 6-digit OTP
  int randomValue = random(100000, 999999);
  char otpString[7]; // 6 digits + null terminator
  sprintf(otpString, "%06d", randomValue);
  return String(otpString);
}

bool verifyFingerprint() {
  Serial.println("Place your finger on the sensor for verification.");
  Serial.println("Remove your finger when prompted.");

  if (finger.getImage() != FINGERPRINT_OK) {
    return false;
  }

  if (finger.image2Tz(1) != FINGERPRINT_OK) {
    return false;
  }

  if (finger.fingerFastSearch() != FINGERPRINT_OK) {
    return false;
  }

  return true;
}