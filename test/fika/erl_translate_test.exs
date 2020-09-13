defmodule Fika.ErlTranslateTest do
  use ExUnit.Case
  alias Fika.{
    Parser,
    ErlTranslate
  }

  test "a function that calls another function" do
    str = """
    fn a do
      x = 1
      b(x)
    end

    fn b(x : Int) do
      x
    end
    """

    ast = Parser.parse_module(str, "test")
    result = ErlTranslate.translate(ast, "/tmp/foo")
    forms = [
      {:attribute, 1, :file, {'/tmp/foo', 1}},
      {:attribute, 1, :module, :test},
      {:attribute, 8, :export, [b: 1]},
      {:attribute, 4, :export, [a: 0]},
      {:function, 8, :b, 1, [{:clause, 8, [{:var, 6, :x}], [], [{:var, 7, :x}]}]},
      {:function, 4, :a, 0,
       [
         {:clause, 4, [], [],
          [
            {:match, 2, {:var, 2, :x}, {:integer, 2, 1}},
            {:call, 3, {:atom, 3, :b}, [{:var, 3, :x}]}
          ]}
       ]}
    ]
    assert result == forms
  end

  test "infix arithmetic operators" do
    str = """
    fn a do
      1+2*3/4
    end
    """

    ast = Parser.parse_module(str, "test_arithmetic")
    result = ErlTranslate.translate(ast, "/tmp/foo")
    forms = [
      {:attribute, 1, :file, {'/tmp/foo', 1}},
      {:attribute, 1, :module, :test_arithmetic},
      {:attribute, 3, :export, [a: 0]},
      {:function, 3, :a, 0,
        [
          {:clause, 3, [], [],
            [
              {:op, 2, :+, {:integer, 2, 1},
                {:op, 2, :/, {:op, 2, :*, {:integer, 2, 2}, {:integer, 2, 3}},
                  {:integer, 2, 4}}}
            ]}
        ]
      }
    ]
    assert result == forms
  end
end