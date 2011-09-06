require 'openssl'
require 'base64'
class Key
  def initialize(key_file, password=nil)
    if password
      @key= OpenSSL::PKey::RSA.new(File.read(key_file), password)
    else
      @key= OpenSSL::PKey::RSA.new(File.read(key_file))
    end
  end
  def encrypt(msg)
    encrypted_string = Base64.encode64(@key.public_encrypt(msg))
  end
  def decrypt(msg)
    decrypted_string = @key.private_decrypt(Base64.decode64(msg))
  end
  def priv_encrypt(msg)
    encrypted_string = Base64.encode64(@key.private_encrypt(msg))
  end
  def pub_decrypt(msg)
    decrypted_string = @key.public_decrypt(Base64.decode64(msg))
  end
end
