json.array!(@phone_calls) do |phone_call|
  json.extract! phone_call, :id, :sms_code
end
