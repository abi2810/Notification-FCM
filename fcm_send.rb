class FcmSend < ApplicationRecord

	## Android Push Notifiation ##
	def self.send_notification(title,respon,user_id,reg_id)
		res1 = ""
     	data = { :registration_ids => reg_id,
                	"data" => {
                                "body" => respon, 
                                "message" => respon,
                                "title" => title,
                                # "icon" => "myicon",
                                # "type" => type,
                                # "json_data" => json_details,
                                # "email" => user_email,
                                                
                              },
            	}

        uri=URI.parse("https://fcm.googleapis.com/fcm/send")
        require 'net/http'
        req = Net::HTTP.new(uri.host, uri.port)
        req1 = Net::HTTP::Post.new(uri.path)
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req.use_ssl = true
        req1.body=JSON.generate(data)
        req1["Content-Type"] = "application/json"
        req1["Authorization"] = "key= xxxx" ##-- Authorization key for android --##
        
        res = req.request(req1)
        	res.each do |val|
            	res1 << val
           	end
           	hash = Hash.new 
	       	hash["res"] = JSON.parse(res.body)
         	hash["reg_id"] = reg_id
        return hash
	end
 
	## iOS Push Notification ##
	def self.apnNewNotification(title,respon,user_id,reg_id)
 		require 'socket'
		require 'http/2'
		payload = '{"aps":{"alert":{"title" : "'+title+'", "body" : "'+respon+'",  "action-loc-key" : "PLAY" },"sound":"default"}}'
		device_token = reg_id
	
		if Rails.env.production?
			uri = URI.parse("https://api.push.apple.com/3/device/#{device_token}")
			cert = File.read('public/xxx.pem')
		else
			uri = URI.parse("https://api.development.push.apple.com/3/device/#{device_token}")
			cert = File.read('public/xxx.pem')  # apple push certificate convert p12 to pem 
		end
	
		tcp = TCPSocket.new(uri.host, uri.port)

		ctx = OpenSSL::SSL::SSLContext.new
		ctx.key = OpenSSL::PKey::RSA.new(cert) #set passphrase here, if any
		ctx.cert = OpenSSL::X509::Certificate.new(cert)
		   
		# For ALPN support, Ruby >= 2.3 and OpenSSL >= 1.0.2 are required
		sock = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
		sock.connect

		conn = HTTP2::Client.new
		stream = conn.new_stream

		conn.on(:frame) do |bytes|
		  puts "Sending bytes: #{bytes.unpack("H*").first}"
		  sock.print bytes
		  sock.flush
		end

		# conn.on(:frame_sent) do |frame|
		#   puts "Sent frame: #{frame.inspect}"
		# end
		# conn.on(:frame_received) do |frame|
		#   puts "Received frame: #{frame.inspect}"
		# end

		# conn.on(:promise) do |promise|
		#   promise.on(:headers) do |h|
		#     log.info "promise headers: #{h}"
		#   end

		#   promise.on(:data) do |d|
		#     log.info "promise data chunk: <<#{d.size}>>"
		#   end
		# end

		# conn.on(:altsvc) do |f|
		#   log.info "received ALTSVC #{f}"
		# end

		# stream.on(:close) do
		#   log.info 'stream closed'
		# end

		# stream.on(:half_close) do
		#   log.info 'closing client-end of the stream'
		# end

		# stream.on(:headers) do |h|
		#   log.info "response headers: #{h}"
		# end

		# stream.on(:data) do |d|
		#   log.info "response data chunk: <<#{d}>>"
		# end

		# stream.on(:altsvc) do |f|
		#   log.info "received ALTSVC #{f}"
		# end
		# return payload
		# payload = payload.to_s

		head = {
		  ':scheme' => uri.scheme,
		  ':method' => "POST",
		  ':path' => uri.path,
		  'content-length' => payload.bytesize.to_s, # should be less than or equal to 4096 bytes
		  'apns-topic' => "topic" # should be less than or equal to 4096 bytes
		}

		puts 'Sending HTTP 2.0 request'
	
		stream.headers(head, end_stream: false)
		stream.data(payload)

		while !sock.closed? && !sock.eof?
	  		data = sock.read_nonblock(1024)
	  		puts "Received bytes: #{data.unpack("H*").first}"
			begin
	    		conn << data
	   			sock.close
	   			tcp.close
			rescue => e
	    		puts "#{e.class} exception: #{e.message} - closing socket."
	    		e.backtrace.each { |l| puts "\t" + l }
	    		sock.close
	   			tcp.close
	  		end
		end
    	return hash
  	end
end



