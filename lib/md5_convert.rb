require 'digest/md5'

module Md5Convert
  def self.get_hashcode(val, start_index, end_index)
    return if ! val
    hashint = nil
    hashcode = Digest::MD5.hexdigest(val)[(start_index)..(end_index)]
    if hashcode then
      hashint = Integer("0x#{hashcode}")
      hashint = -1 - 0xffffffff ^ hashint if (0x80000000 & hashint) != 0
      return hashint
    end
  end
end
