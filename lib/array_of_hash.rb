module ArrayOfHash
  def self.create_hash_by(records, key_list)
    ret = {}
    if records && key_list then
      records = [records] if ! records.is_a? Array
      key_list = [key_list] if ! key_list.is_a? Array
      
      records.each do |record|
        val_list = record.values_at *key_list
        last_val = val_list.pop
        hash = ret
        val_list.each do |key|
          hash = ret[key] ||= {}
        end
        hash[last_val] = record
      end
    end
    return ret
  end
  
  def self.split_records_by(records, key_list)
    ret = {}
    if records && key_list then
      records = [records] if ! records.is_a? Array
      key_list = [key_list] if ! key_list.is_a? Array
      
      records.each do |record|
        val_list = record.values_at *key_list
        last_val = val_list.pop
        hash = ret
        val_list.each do |key|
          hash = ret[key] ||= {}
        end
        hash[last_val] ||= []
        hash[last_val].push record
      end
    end
    return ret
  end
end
