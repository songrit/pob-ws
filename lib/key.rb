require 'openssl'
require 'base64'
class Key
  def encrypt(msg, public_key_file)
    public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))
    encrypted_string = Base64.encode64(public_key.public_encrypt(msg))
  end
  def decrypt(msg, private_key_file, password)
    private_key = OpenSSL::PKey::RSA.new(File.read(private_key_file),password)
    decrypted_string = private_key.private_decrypt(Base64.decode64(msg))
  end
end
