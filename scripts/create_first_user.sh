host="$1"
email="$2"
password="$3"
firstName="$4"
lastName="$5"
output="$6"
my_ip=$(curl --silent ifconfig.me)
http_code=$(curl --digest \
     --silent \
     --show-error \
     --fail \
     --header "Accept: application/json" \
     --header "Content-Type: application/json" \
     --request POST "http://${host}:8080/api/public/v1.0/unauth/users?accessList=${my_ip}&whitelist=${my_ip}" \
     --data '
       {
         "username": "'${email}'",
         "password": "'${password}'",
         "firstName": "'${firstName}'",
         "lastName": "'${lastName}'"
       }' \
    --output "../${output}.tmp" \
    --write-out "%{http_code}")

if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    echo "✓ User created successfully (HTTP $http_code)"
    mv "../${output}.tmp" "../${output}"
    exit 0
else
    echo "✗ Failed to create user (HTTP $http_code)"
    rm "../${output}.tmp"
    exit 1
fi