require 'socket'
require 'json'
require 'em-websocket'

$clients_counter = 0
$data = Hash["0"=>0,"1"=>1,"2"=>2,"3"=>3,"4"=>4,"5"=>5,"6"=>6,"7"=>7,"8"=>8,"9"=>9]
$operations_counter = 0
$_l1_b1

current_port = '9002'
websocket_port = '9102'
socket = TCPServer.open(current_port)

#Donem 10 segons per encendre tots els servidors de la Core-Layer abans de fer la full-mesh
sleep(5)
#Connexio amb A1 i A3
hostname = 'localhost'
port_a1 = '9001'
port_a3 = '9003'
client1 = TCPSocket.open(hostname, port_a1)
client3 = TCPSocket.open(hostname, port_a3)

puts "A2 connected to A1"
puts "A2 connected to A3"

def send_data_to_websocket(ws)
  while true do
    ws.send JSON[$data]
    sleep 1
  end
end

def run_websocket_server(hostname, websocket_port)
  EM.run do
    EM::WebSocket.run(:host => hostname, :port => websocket_port) do |ws|
      ws.onopen{ |handshake|
        puts "WebSocket connection open"
        ws.send "Client connected to Core Layer A2"

        Thread.new{ send_data_to_websocket(ws) }
      }

      ws.onclose { puts "Connection closed" }
    end
  end
end

Thread.new{ run_websocket_server(hostname, websocket_port) }

Signal.trap("INT") do
  #Send data to Layer 1
  $_l1_b1.puts(JSON[$data])
end

def server_connection_handler(client)
  #Eager Replication
  while (msg = client.gets)
    split = msg.split('-')
    index = split[0]
    data = split[1].chop
    $data[index] = data

    puts "REPLICATION: key[#{index}] => #{$data[index]}"
    # File.write('./logs/a2', JSON[$data] + "\n", mode: 'a')
    client.puts("ACK")
    
    $operations_counter += 1
    puts $operations_counter
    if $operations_counter == 10
      $operations_counter -= 10
      #Process.kill("INT", Process.pid)
      $_l1_b1.puts(JSON[$data])
    end
  end
end

def client_connection_handler(client, a1, a3)
  write_index = 0
  puts "New client connection! #{client}"

  client.puts("Core Layer - A2")

  transaction_id = client.gets
  puts transaction_id

  transaction = client.gets
  puts transaction

  transaction_commands = transaction.split(',')

  transaction_commands.each do |i|
    if i.include? "c"
      #File.write('./logs/a2', JSON[$data] + "\n", mode: 'a')
      client.puts("Full transaction processed")
      break
    else
      if i.include? "w"
        write_index = i.delete("^0-9")
        next
      end
      if i.include? "r"
        index = i.delete("^0-9")
        puts "READ: key[#{index}] => #{$data[index]}"
        #Return the data to the client
        client.puts("READ: key[#{index}] => #{$data[index]}")
      end
      if !(i.include? "r") && !(i.include? "w") && !(i.include? "b") && !(i.include? "c")
        $data[write_index] = i.delete("^0-9")
        puts "WRITE: key[#{write_index}] => #{$data[write_index]}"
        #Notify other servers - Eager Replication
        a1.puts(write_index + "-" + $data[write_index])
        a3.puts(write_index + "-" + $data[write_index])
        #Wait for their ACK
        ack1 = a1.gets
        ack3 = a3.gets
        if ack1 == "ACK\n" && ack3 == "ACK\n"
          puts "All servers have processed the operation"
        end

        $operations_counter += 1
        puts $operations_counter

        if $operations_counter == 10
          $operations_counter -= 10
          #Process.kill("INT", Process.pid)
          $_l1_b1.puts(JSON[$data])
        end
      end
    end
  end
end

loop do
  client = socket.accept

  $clients_counter += 1

  case $clients_counter
    when 1..2
      Thread.new{ server_connection_handler(client) }
  when 3
      $_l1_b1 = client
  else
      puts "Client connected"
      Thread.new{ client_connection_handler(client, client1, client3) }
  end

end