#openssl pkcs12 -clcerts -nokeys -out apns-dev-cert-macos.pem -in push_cert.p12
openssl pkcs12 -nocerts -out apns-dev-key.pem -in Shaker.p12
openssl rsa -in apns-dev-key.pem -out apns-dev-key-noenc.pem
rm apns-macos-dev.pem
cat apns-dev-cert-macos.pem apns-dev-key-noenc.pem > apns-macos-dev.pem
#openssl pkcs12 -clcerts -nokeys -out apns-dev-cert-ios.pem -in push_cert_ios.p12
rm apns-ios-dev.pem
cat apns-dev-cert-ios.pem apns-dev-key-noenc.pem > apns-ios-dev.pem
