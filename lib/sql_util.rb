# SqlUtil
module SqlUtil
  
  def self.sql_value(val, options={})
    if options[:model] then
#      if options[:sanitize] then
        return options[:model].sanitize val
#      else
#        if val.is_a?(String) then
#          return options[:model].sanitize val
#        end
#      end
    end
    return val
  end
  
  def self.compare_cond(compare_sql, val_list, options ={})
    return 'true' if val_list == nil || val_list == []
    if ! val_list.is_a? Array then
      val_list = [val_list]
    end
    val_list = val_list.map{|val| self.sql_value val, options}
    
    join_op = 'or'
    if compare_sql =~ /\/((and)|(or))$/ then
      compare_sql = $`
      join_op = $1
    end
    
    val_list = val_list.map{|val| "#{compare_sql} #{val}"}
    return val_list.join(" #{join_op} ")
  end

  def self.exclude_cond(var_name, val_list, options ={})
    return 'true' if val_list == nil || val_list == []
    return self.compare_cond("#{var_name} != /and", val_list, options)
  end

  def self.include_cond(var_name, val_list, options ={})
    return 'true' if val_list == nil
    return 'false' if val_list == []
    return self.compare_cond("#{var_name} = /or", val_list, options)
  end
  
  def self.union_sql(select_list)
    return select_list.map{|select_sql| "(#{select_sql})"}.join "union\n"
  end
  
  def self.and_cond(cond_list)
    return nil if cond_list == nil
    return cond_list if ! cond_list.is_a? Array
    cond_list.compact!
    cond_list.uniq!
    return 'false' if cond_list.include? 'false'
    cond_list.delete_if{|cond| cond == 'true'}
    return 'true' if cond_list == []
    return cond_list.map{|cond| "(#{cond})"}.join(' and ')
  end
  
  def self.or_cond(cond_list)
    return nil if cond_list == nil
    return cond_list if ! cond_list.is_a? Array
    cond_list.compact!
    cond_list.uniq!
    return 'true' if cond_list.include? 'true'
    cond_list.delete_if{|cond| cond == 'false'}
    return 'false' if cond_list == []
    return cond_list.map{|cond| "(#{cond})"}.join(' or ')
  end
  
  def self.limit_offset_sql(limit, offset)
    limit = "limit #{limit.to_i}" if limit
    offset = "offset #{offset.to_i}" if offset
    return "#{limit} #{offset}"
  end
  
  def self.where_sql(cond_list)
    return nil if cond_list == nil
    cond_sql = self.and_cond cond_list
    return nil if ! cond_sql || cond_sql == 'true'
    return "where #{cond_sql}"
  end
  
  def self.count_sql(sql)
    return nil if sql == nil
    return "select count(*) from (#{sql}) as alias_sql"
  end
  
  def self.select_values_sql(val_list)
    return '*' if val_list == nil
    if val_list.is_a?(Array) then
      return val_list.join(', ')
    else
      return val_list.to_s
    end
  end
  
  def self.order_by_sql(order_list)
    return "" if order_list == nil
    if !order_list.is_a?(Array) then
      order_list = [order_list]
    end
    order_list = order_list.map{|order|
      if order.to_s =~ /_((asc)|(desc))$/ then
        "#{$`} #{$3}"
      else
        order
      end
    }.compact
    return nil if order_list == []
    return "order by #{order_list.join(', ')}"
  end
  
  def self.select_sql(table_name, options)
    return <<-EOF
      select #{SqlUtil.select_values_sql(options[:select])}
      from #{table_name}
      #{SqlUtil.where_sql(options[:conditions])}
      #{SqlUtil.order_by_sql(options[:order])}
      #{SqlUtil.limit_offset_sql(options[:limit], options[:offset])}
    EOF
  end

  def self.count_sql(table_name, options)
    return <<-EOF
      select count(*) from (
        select #{SqlUtil.select_values_sql(options[:select])}
        from #{table_name}
        #{SqlUtil.where_sql(options[:conditions])}
        #{SqlUtil.limit_offset_sql(options[:limit], options[:offset])}
      ) as alias
    EOF
  end

end


# module ArrayOfHash
  # def self.split_records_by(records, key_list)
    # ret = {}
    # if records && key_list then
      # if ! key_list.is_a? Array then
        # key_list = [key_list]
      # end
      # records.each do |record|
        # val_list = record.values_at *key_list
        # last_val = val_list.pop
        # hash = ret
        # val_list.each do |key|
          # hash = ret[key] ||= {}
        # end
        # hash[last_val] ||= []
        # hash[last_val].push record
      # end
    # end
    # return ret
  # end
# end
# 
