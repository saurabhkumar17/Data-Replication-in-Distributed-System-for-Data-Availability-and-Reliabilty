require 'socket'

port = ''
hostname = 'localhost'

def random_server(layer)
  case layer
  when 0
    [9001, 9002, 9003].sample
  when 1
    [9011, 9012].sample
  when 2
    [9021, 9022].sample
  else
    puts "Random_server went wrong!"
  end
end

#Implicit Return function
def read_only_detector(transaction_type)
  if transaction_type == "b"
    0
  else
    #The deleted number is returned
    transaction_type.delete("^0-9")
  end
end


file = File.open("transactions").read
file.gsub!(/\r\n?/, "\n")

file.each_line.with_index do |line, transaction_id|

  splits = line.split( ',')
  layer = read_only_detector( splits[0].strip)

  #Server assignation
  case layer.to_i
  when 0 #Core-Layer  
    port = random_server(0)
  when 1 #Layer 1
    port = random_server(1)
  when 2 #Layer 2
    port = random_server(2)
  else puts "Nako"
  end
  # if transaction_id == 0
  #   port = 9002
  # end
  # if transaction_id == 1
  #   port = 9003
  # end

  #Server connection
  connection = TCPSocket.open(hostname, port)

  connection.puts("Transaction : " + transaction_id.to_s)
  connection.puts( + line + "\n")
  response = connection.gets
  puts "Running transaction in: " + response

  while (read_operation = connection.gets)
    if read_operation.chop.eql? "Full transaction processed"
      puts read_operation.chop
      break
    end
    puts read_operation.chop
  end


  connection.close
end