defmodule DeserializerTest do
  use ExUnit.Case, async: true
  doctest Ringbahn.Deserializer

  test "deserializer should serialize into expected response tuple" do
    raw_data = "f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 2:21, HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nDA"

    assert Ringbahn.Deserializer.deserialize(raw_data) == {:ok, {"f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0", 21, {200, [{"content-length", "2"}], "DA"}}}
  end

  test "deserializer should throw an error in case of malformed netstring response" do
    raw_data = "f983c23e-9058-4c9c-8cec-7f9f9a34c9ab-0 10:1, HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nDA"

    assert_raise MatchError, fn ->
      Ringbahn.Deserializer.deserialize(raw_data)
    end
  end
end
