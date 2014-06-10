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
Mailman::Application.run do

  puts "mailman runned"

  default do
    begin
      puts "incoming mail".green
#      puts "#{message.inspect}".cyan
#      puts "#{message.to_s}".yellow
#      IncomingMessage.receive(message) ## Troubles
      puts message.parse_body.white
    rescue Exception => e
      Mailman.logger.error "Exception occured while receiving message:\n#{message}"
      Mailman.logger.error [e, *e.backtrace].join('\n')
    end
  end

  #--------------------------------------------------------- та самая "магия" :) -----------------------------------------------------------
  class Mail::Message

    #-------------------------------------------------------------------------------------------------
    def parse_body                                     # расширение класса Mail::Message - "выдёргивает html или текст из тела почтового сообщения"
      res = []                                         # результат
      parts_cache = [""]                               # Запоминаем всё, на случай если отсутствует тип контента text/html - посылаем то что есть
      body_parts = self.body.parts
      body_parts = [self] if body_parts.size == 0
      body_parts.each do |part|                   # сообщение может состоять из нескольких частей, все их проверяем
#        puts "#{part.content_type}".cyan               # Что за контент посмотрим
        if part.content_type[/multipart/]              # Если эта часть - составная, применим рекурсию
          res << part.parse_body                       # Рекурсивный вызов
        elsif part.content_type[/text\/html/]          # Предпочтительный вариант
#          encode = get_encode part.content_type        # определим кодировку текста в этой части сообщения
          res << part.decoded                          # .decoded возвращает часть сообщения из base64 или любой другой кодировки
        elsif part.content_type[/text\/[a-z]+/]                # любые остальные варианты, которые могут содержать текст сообщения (вложения не имеют значения)
#          encode = get_encode part.content_type        # определим кодировку текста в этой части сообщения
          parts_cache << part.decoded              #.decode_from_to encode, "utf-8"
        end
      end
#      puts "res: #{res}".green                              # Посмотрим возвращаемый результат
#      puts "parts_cache: #{parts_cache}".green              # Посмотрим всё, не вошедшее в результат, но что может быть интерпретировано как текст
      (res.size > 0 ? res : parts_cache).join.strip          # Возвращаем предпочтительный вариант или всё, что было из текста в виде простой строки
    end

#    #-------------------------------------------------------------------------------------------------
#    def get_encode content_type
#      (content_type[/(?<=charset=)[a-zA-Z0-9-]+/] || "").downcase
#    end

  end


#  #-------------------------------------------------------------------------------------------------
#  class String
#    def decode_from_to source_encode, dest_encode
#      puts "enc: #{source_encode} -> #{dest_encode}".yellow
#      puts "decode from: #{self}"
#      if source_encode == dest_encode
#        res = self
#      else
#        ec = Encoding::Converter.new(source_encode, dest_encode)
#        res = ec.convert self
#      end
#      puts "decode to: #{res}"
#      res
#    end
#  end


end
