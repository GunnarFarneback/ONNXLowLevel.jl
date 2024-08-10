module REPLExt

using REPL.TerminalMenus: _ConfiguredMenu, Config, ARROW_LEFT, ARROW_RIGHT,
                          request
import REPL.TerminalMenus: options, writeline, keypress, cancel,
                           pick, selected, header
import ONNXLowLevel
import ONNXLowLevel: explore, @explore

struct Entry
    object::Any
    name::String
    text::String
    is_empty::Bool
end

function Entry(object, name::Symbol, text, is_empty)
    return Entry(object, String(name), text, is_empty)
end

mutable struct View
    object::Any
    entries::Vector{Entry}
    pageoffset::Int
    cursor::Int
    location::String
end

function View(x, location, skip_empty, max_vector)
    return View(x, filter_empty(entries(x, max_vector), skip_empty),
                0, 1, location)
end

mutable struct MenuData
    view_stack::Vector{View}
end

mutable struct Menu <: _ConfiguredMenu{Config}
    pagesize::Int
    pageoffset::Int
    options::Vector{String}
    cursor::Base.RefValue{Int}
    views::Vector{View}
    skip_empty::Bool
    max_vector::Int
    show_help::Bool
    locations_to_print::Vector{String}
    config::Config
end

# Note: pagesize => 11 makes all help lines fit without scrolling.
function Menu(x, pagesize::Int = 20; name = "", skip_empty = true,
              max_vector = 10000, kwargs...)
    pageoffset = 0
    cursor = Ref(1)
    views = [View(x, name, skip_empty, max_vector)]
    options = copy([entry.text for entry in last(views).entries])
    menu = Menu(pagesize, pageoffset, options, cursor, views, skip_empty,
                max_vector, false, String[], Config(; kwargs...))
    return menu
end

function entries(x::Vector, max_vector)
    return [entry(x[n], "[$n]", max_vector) for n in eachindex(x)]
end

function entries(x, max_vector)
    T = typeof(x)
    return [entry(getfield(x, field), field, max_vector)
            for field in fieldnames(T)]
end

function entry(x::Union{Number, Bool}, field, _)
    return Entry(nothing, field, string("$(field): $(x)"), false)
end

function entry(x::AbstractString, field, _)
    x = replace(x, "\n" => "\\n", "\t" => "\\t")
    s = string("$(field): \"$(x)\"")
    width = last(displaysize(stdout))
    if length(s) > width - 4
        s = s[1:(width - 8)] * "..."
    end
    return Entry(nothing, field, s, isempty(x))
end

function entry(::Nothing, field, _)
    return Entry(nothing, field, string("$(field): nothing"), true)
end

function entry(x::Vector, field, max_vector)
    isempty(x) && return Entry(nothing, field, string("$(field): empty vector"), true)
    length(x) == 1 && return Entry(x, string(field), string(bold(field), ": 1 element"), false)
    if length(x) > max_vector
        return Entry(nothing, string(field), string(bold_gray(field), ": $(length(x)) elements"), false)
    end        
    return Entry(x, string(field), string(bold(field), ": $(length(x)) elements"), false)
end

function entry(x::Symbol, field, _)
    return Entry(nothing, field, string("$(field): :$(x)"), isempty(string(x)))
end

function entry(x::Enum, field, _)
    return Entry(nothing, field, string("$(field): $(x)"), false)
end

function entry(x, field, _)
    return Entry(x, field, bold(field), false)
end

# Actually both bold and green.
bold(s) = string("\033[1m\033[38;5;10m$(s)\033[39m\033[0m")

bold_gray(s) = string("\033[1m\033[38;5;8m$(s)\033[39m\033[0m")

function filter_empty(entries, skip_empty)
    skip_empty || return entries
    non_empty = filter(entry -> !entry.is_empty, entries)
    isempty(non_empty) && return entries
    return non_empty
end

is_nothing_or_empty(::Nothing) = true
is_nothing_or_empty(x::Vector) = isempty(x)
is_nothing_or_empty(x::AbstractString) = isempty(x)
is_nothing_or_empty(::Any) = false

function push_view!(menu::Menu, x, name)
    view = last(menu.views)
    view.pageoffset = menu.pageoffset
    view.cursor = menu.cursor[]
    location = compose_location(view.location, name)
    push!(menu.views, View(x, location, menu.skip_empty, menu.max_vector))
    update_menu!(menu)
end

function compose_location(location, name)
    if startswith(name, "[")
        return location * name
    elseif isletter(first(name))
        return location * "." * name
    else
        return location * ".var\"" * name * "\""
    end
end

function pop_view!(menu::Menu)
    pop!(menu.views)
    update_menu!(menu)
end

function update_menu!(menu::Menu)
    view = last(menu.views)
    menu.options = [entry.text for entry in view.entries]
    menu.pageoffset = view.pageoffset
    menu.cursor[] = view.cursor
end

function get_help_texts()
    return split("""
                 ?:             Toggle show help
                 ARROW RIGHT:   Enter field
                 ARROW LEFT:    Go back
                 p:             Print location when done
                 q:             Quit
                 ARROW UP:      Move up
                 ARROW DOWN:    Move down
                 PAGE UP:       Move page up
                 PAGE DOWN:     Move page down
                 HOME:          Move to first item
                 END:           Move to last item
                 """, "\n", keepempty = false)
end

options(menu::Menu) = menu.options

cancel(menu::Menu) = nothing

selected(menu::Menu) = nothing

function pick(menu::Menu, cursor::Int)
    if menu.show_help
        update_menu!(menu)
        menu.show_help = false
    end
    return false
end

function keypress(menu::Menu, c::UInt32)
    if menu.show_help
        update_menu!(menu)
        menu.show_help = false
    elseif c == Int('?')
        view = last(menu.views)
        view.pageoffset = menu.pageoffset
        view.cursor = menu.cursor[]
        menu.options = get_help_texts()
        menu.cursor[] = 1
        menu.pageoffset = 0
        menu.show_help = true
    elseif c == Int('p') || c == Int('P')
        view = last(menu.views)
        location = compose_location(view.location,
                                    view.entries[menu.cursor[]].name)
        push!(menu.locations_to_print, location)
    elseif c == Int(ARROW_RIGHT)
        entry = last(menu.views).entries[menu.cursor[]]
        if !isnothing(entry.object)
            push_view!(menu, entry.object, entry.name)
        end
    elseif c in (Int(ARROW_LEFT))
        if length(menu.views) > 1
            pop_view!(menu)
        end
    end
    return false
end

function writeline(buf::IOBuffer, menu::Menu, idx::Int, iscursor::Bool)
    print(buf, menu.options[idx])
end

function header(menu::Menu)
    menu.show_help && return ""
    view = last(menu.views)
    location = view.location * ": " * string(typeof(view.object))
    width = last(displaysize(stdout))
    if length(location) > width - 4
        location = string("...", location[(end - (width - 4)):end])
    end
    if length(menu.views) == 1
        return "q to quit, ? for help\n" * location
    end
    return location
end

explore_docstring = """
    explore(object)

Interactively explore the contents of an ONNX object.

Navigate with the four arrow keys. Quit with `q`. Press `p` to mark an
element for printing of the indexing expression needed to access
it. Marked elements are printed after exploration is finished. Press
`?` for online help.

    explore(object, name)

Prepend the indexing expression with `name`.

    @explore object

Call `explore` with the name of the variable filled in as second
argument.

    explore(filename)
    @explore filename

If called with a string, call `load` and explore the result.

Keyword arguments:
* `skip_empty`: If `false`, also show fields with empty or `nothing` contents.
* `max_vector`: Maximum vector length that can be explored. Defaults to 10000.
"""

"$explore_docstring"
function explore(object, name = ""; skip_empty = true, max_vector = 10000,
                 kwargs...)
    if object isa Vector
        if length(object) > max_vector
            println("Vector is too long to be explored (can be configured with max_vector keyword argument).")
        end
    elseif isempty(fieldnames(typeof(object)))
        println("Only vectors and composite types can be explored.")
        return
    end
    menu = Menu(object; name, skip_empty, max_vector, kwargs...)
    request(menu, cursor = menu.cursor)
    isempty(menu.locations_to_print) || println()
    foreach(println, menu.locations_to_print)
end

function explore(filename::AbstractString, name = ""; kwargs...)
    explore(ONNXLowLevel.load(filename), name; kwargs...)
end

"$explore_docstring"
macro explore(object)
    return quote
        if $object isa AbstractString
            explore($object, "")
        else
            explore($object, $(string(object)))
        end
    end |> esc
end

end
