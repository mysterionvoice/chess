require "json"

module GameSerialize
  @@serializer = JSON

  def serialize
    obj = {}
    instance_variables.map do |var|
      obj[var] = instance_variable_get(var)
    end
    @@serializer.dump obj
  end

  def json_create(object)
    if object.is_a?(Hash)
      for key, value in object
        if key == "Player"
          obj = Player.new('placeholder', true)
        elsif key == "Chess_AI"
          obj = Chess_AI.new(true, 0)
        elsif key == "Board"
          obj = Board.new
        elsif key == "Pawn"
          obj = Pawn.new(true)
        elsif key == "Rook"
          obj = Rook.new(true)
        elsif key == "Bishop"
          obj = Bishop.new(true)
        elsif key == "Queen"
          obj = Queen.new(true)
        elsif key == "King"
          obj = King.new(true)
        elsif key == "Knight"
          obj = Knight.new(true)
        else
          return object
        end
        return obj.unserialize(value.to_json)
      end
    elsif object.is_a?(Array)
      obj = []
      object.each do |item|
        obj.push(json_create(item))
      end
      return obj
    else
      return object
    end
  end

  def unserialize(string)
    obj = @@serializer.parse(string)
    obj.keys.each do |key|
      instance_variable_set(key, json_create(obj[key]))
    end
    return self
  end

  def to_json(*a)
    data = {}
    instance_variables.map do |var|
      data[var] = instance_variable_get(var)
    end
    { self.class.name => data }.to_json(*a)
  end
end