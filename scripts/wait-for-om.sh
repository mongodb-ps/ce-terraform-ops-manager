host=$1
port=$2

until nc -z -v -w5 $host $port
do
  echo "Waiting for Ops Manager connection at $host:$port ..."
  # wait for 10 seconds before check again
  sleep 10
done