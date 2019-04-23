push!(LOAD_PATH, "../src/")
using Documenter, LabjackU6Library

makedocs(
  sitename = "LabjackU6Library.jl",
  authors = "Markus Petters",
  pages = [
    "Home" => "index.md",
    "License" => "licence.md",
    "Foo" => "foo.md"
  ]

)
