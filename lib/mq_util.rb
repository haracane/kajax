require 'rubygems'
require 'bunny'

module MqUtil
  def self.get_mq_message_count(queue_name, mq_options)
    mq_options = mq_options.merge(:logging=>false, :spec=>'09')
    bunny = Bunny.new(mq_options)
    bunny.start
    queue = bunny.queue(queue_name, :durable=>mq_options[:durable])
    ret = queue.status[:message_count]
    bunny.stop
    return ret
  end

  def self.get_mq_message_counts(queue_name_list, mq_options)
    ret = {}
    mq_options = mq_options.merge(:logging=>false, :spec=>'09')
    bunny = Bunny.new(mq_options)
    bunny.start
    queue_name_list.each do |queue_name|
      queue = bunny.queue(queue_name, :durable=>mq_options[:durable])
      ret[queue_name] = queue.status[:message_count]
    end
    bunny.stop
    return ret
  end
  
  def self.delete_queue(queue_name, mq_options)
    mq_options = mq_options.merge(:logging=>false, :spec=>'09')
    bunny = Bunny.new(mq_options)
    bunny.start
    queue = bunny.queue(queue_name, :durable=>mq_options[:durable])
    ret = queue.delete
    bunny.stop
    return ret
  end

  def self.delete_queues(queue_name_list, mq_options)
    ret = {}
    mq_options = mq_options.merge(:logging=>false, :spec=>'09')
    bunny = Bunny.new(mq_options)
    bunny.start
    queue_name_list.each do |queue_name|
      queue = bunny.queue(queue_name, :durable=>mq_options[:durable])
      ret[queue_name] = queue.delete
    end
    bunny.stop
    return ret
  end
  
  def self.create_binded_direct_exchange(bunny, queue_name, exchange_options)
    direct_exchange = bunny.exchange(queue_name, exchange_options)
    queue = bunny.queue(queue_name, :durable=>exchange_options[:persistent])
    queue.bind(direct_exchange)
    return direct_exchange
  end
end