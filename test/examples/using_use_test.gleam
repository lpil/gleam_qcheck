import gleam/string
import gleeunit/should
import qcheck/generator
import qcheck/qtest
import qcheck/qtest/config as qtest_config

const short_test_count: Int = 100

pub fn using_use__test() {
  let generator = {
    use n <- generator.map(generator.small_positive_or_zero_int())

    n + 10
  }

  {
    use n <- qtest.run(config: qtest_config.default(), generator: generator)

    n >= 10
  }
  |> should.equal(Ok(Nil))
}

type Person {
  Person(name: String, age: Int)
}

fn make_person(name, age) {
  let name = case name {
    "" -> Error("name must be a non-empty string")
    name -> Ok(name)
  }

  let age = case age >= 0 {
    False -> Error("age must be >= 0")
    True -> Ok(age)
  }

  case name, age {
    Ok(name), Ok(age) -> Ok(Person(name, age))
    Error(e), Ok(_) | Ok(_), Error(e) -> Error([e])
    Error(e1), Error(e2) -> Error([e1, e2])
  }
}

fn valid_name_and_age_generator() {
  let name_generator = generator.string_non_empty()
  let age_generator = generator.int_uniform_inclusive(low: 0, high: 129)

  use name, age <- generator.map2(g1: name_generator, g2: age_generator)

  #(name, age)
}

pub fn person__test() {
  {
    use #(name, age) <- qtest.run_result(
      config: qtest_config.default()
        |> qtest_config.with_test_count(short_test_count),
      generator: valid_name_and_age_generator(),
    )

    make_person(name, age)
  }
  |> should.equal(Ok(Nil))
}

pub fn bind_with_use__test() {
  let generator = {
    use bool <- generator.bind(generator.bool())

    case bool {
      True -> {
        use n <- generator.map(generator.small_positive_or_zero_int())

        Ok(n)
      }
      False -> {
        use s <- generator.map(generator.string_non_empty())

        Error(s)
      }
    }
  }

  {
    use generated_value <- qtest.run(
      config: qtest_config.default()
        |> qtest_config.with_test_count(short_test_count),
      generator: generator,
    )

    case generated_value {
      Ok(n) -> n >= 0
      Error(s) -> string.length(s) >= 0
    }
  }
  |> should.equal(Ok(Nil))
}
