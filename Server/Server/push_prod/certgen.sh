openssl pkcs12 -clcerts -nokeys -out apns-prod-cert-macos.pem -in push_cert.p12
openssl pkcs12 -nocerts -out apns-prod-key.pem -in shaker.p12
openssl rsa -in apns-prod-key.pem -out apns-prod-key-noenc.pem
rm apns-macos-prod.pem
cat apns-prod-cert-macos.pem apns-prod-key-noenc.pem > apns-macos-prod.pem
openssl pkcs12 -clcerts -nokeys -out apns-prod-cert-ios.pem -in push_cert_ios.p12
rm apns-ios-prod.pem
cat apns-prod-cert-ios.pem apns-prod-key-noenc.pem > apns-ios-prod.pem
