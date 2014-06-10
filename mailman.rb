#!/usr/bin/env ruby

require 'colorize'
require 'rubygems'
require 'bundler/setup'
require 'mailman'
require 'base64'

Mailman.config.maildir = 'Mail'
Mailman.config.poll_interval = 5
Mailman.config.logger = Logger.new('log/mailman.log')

Mailman.config.imap = {
    server: 'multi21.hostsila.org',
    port: 993,  # usually 995, 993 for gmail
    ssl: true,
    username: 'inbox@archivizer.com',
    password: 'xlxuQwZ6o8Vk'
}

#-------------------------------------------------------------------------------------------------
def get_encode content_type
  content_type.[/(?<=charset=)[a-zA-Z0-9-]+/] || "").downcase
end

#-------------------------------------------------------------------------------------------------
Mailman::Application.run do

  puts "mailman runned"

  default do
    begin
      puts "incoming mail".green
#      puts message.inspect
#      puts message.to_s.yellow
#      IncomingMessage.receive(message) ## Troubles
      puts message.parse_body.white
    rescue Exception => e
      Mailman.logger.error "Exception occured while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join('\n')
    end
  end

  #--------------------------------------------------------- та самая "магия" :) -----------------------------------------------------------
  class Mail::Message
    def parse_body                                     # расширение класса Mail::Message - "выдёргивает html или текст из тела почтового сообщения"
      res = []                                         # результат
      parts_cache = [""]                               # Запоминаем всё, на случай если отсутствует тип контента text/html - посылаем то что есть
      body_parts = self.body.parts
      body_parts = [self.body] if body_parts.size == 0
      body_parts = [self] if body_parts.size == 0
#      puts "body_parts-1. #{body_parts.inspect}"
#      puts "body_parts-1. #{body_parts.inspect}"
#      puts "body_parts-1. #{body_parts.inspect}"
#      body_parts.size ||= [self.body]
#      puts body_parts.inspect
#      body_parts ||= [self]
#      puts body_parts.inspect
      begin
        body_parts.each do |part|                   # сообщение может состоять из нескольких частей, все их проверяем
#          puts part.content_type.to_s.cyan               # Что за контент посмотрим
          if part.content_type.to_s[/multipart/]
#            puts "multipart: "+part.parse_body[0..1000].green
            decoded_text = part.parse_body
          else
#            puts part.decoded.to_s[0..100].blue
            encode = get_encode(part.content_type) # определим кодировку текста в этой части сообщения
#            puts encode.to_s.yellow
            if part.content_type[/text/]
              unless encode[/utf-8/]                       # если кодировка в теле сообщения не utf-8 - конвертируем в utf-8
                decoded_text = part.decoded.decode_from_to encode, "utf-8"
              else
                decoded_text = part.decoded
              end
            else
              decoded_text = ""
            end
          end
#          puts "Кодировка: '#{encode}'".yellow
          if get_encode(part.content_type)               # предпочтительный вариант
            res << decoded_text                          # .decoded возвращает часть сообщения из base64 или любой другой кодировки
          elsif part.content_type[/text/]                # любые остальные варианты, которые могут содержать текст сообщения (вложения не имеют значения)
            parts_cache << decoded_text
          end
        end
      rescue
      end
      res = (res.size > 0 ? res : parts_cache).join.strip          # Возвращаем предпочтительный вариант или всё, что было из текста в виде простой строки
      puts "res1: '#{res}'".red
      if res == ''
#        puts "body_parts.methods: #{body_parts[0].methods.inspect}".red
#        puts body_parts[0].encoding
        encode = get_encode(self.content_type)
        puts "encode: #{encode}".green
        if encode[/utf-8/]
          res = body_parts[0].decoded
        else
          res = body_parts[0].decoded.decode_from_to encode, 'utf-8'
        end
      end
      res
    end
  end

  #-------------------------------------------------------------------------------------------------
  class String
    def decode_from_to source_encode, dest_encode
      ec = Encoding::Converter.new(source_encode, dest_encode)
      ec.convert self
    end
  end

end
