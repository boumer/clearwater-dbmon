require 'opal'
require 'clearwater'
require 'clearwater/dom_reference'

class Layout
  include Clearwater::Component

  def render
    `Monitoring.renderRate.ping()`

    div([
      DBMon.new(`ENV.generateData().toArray()`),
    ])
  end
end

class Query
  include Clearwater::Component
  include Clearwater::CachedRender

  attr_reader :query, :format_elapsed, :elapsed_class

  def initialize(query:, format_elapsed:, elapsed_class:)
    @query = query
    @format_elapsed = format_elapsed
    @elapsed_class = elapsed_class
  end

  def should_render? previous
    !(
      `#{query} === #{previous.query}` &&
      `#{format_elapsed} === #{previous.format_elapsed}` &&
      `#{elapsed_class} == #{previous.elapsed_class}`
    )
  end

  def render
    td({ className: "Query #{elapsed_class}" }, [
      span(format_elapsed.to_s),
      div({ className: 'popover left' }, [
        div({ className: 'popover-content' }, query.to_s),
        div({ className: 'arrow' })
      ]),
    ])
  end
end

class Database
  include Clearwater::Component
  include Clearwater::CachedRender

  attr_reader :name, :count_class, :query_count, :top_five, :last_mutation_id

  def initialize(name:, last_sample:, last_mutation_id:)
    @name = name
    @count_class = `last_sample.countClassName`
    @query_count = `last_sample.nbQueries`
    @top_five = `last_sample.topFiveQueries`
    @last_mutation_id = last_mutation_id
  end

  def should_render? previous
    return true unless last_mutation_id == previous.last_mutation_id

    false
  end

  def render
    tr([
      td({ className: 'dbname' }, name),
      td({ className: 'query-count' }, [
        span({ className: count_class }, query_count.to_s),
      ]),
      top_five.map { |query|
        Query.new(
          query: `query.query`,
          format_elapsed: `query.formatElapsed`,
          elapsed_class: `query.elapsedClassName`,
        )
      },
    ].flatten)
  end
end

class DBMon
  include Clearwater::Component

  attr_reader :databases

  def initialize databases
    @databases = databases
  end

  def should_render? previous
    !databases.equal?(previous.databases)
  end

  def render
    div({ attributes: { 'aria-label': 'hi' } }, [
      table({ className: 'table table-striped latest-data' }, [
        tbody(@databases.map { |db|
          Database.new(
            name: `db.dbname`,
            last_sample: `db.lastSample`,
            last_mutation_id: `db.lastMutationId`,
          )
        })
      ]),
    ])
  end
end

# Clearwater::Component.no_debug!

app = Clearwater::Application.new(
  component: Layout.new,
  element: Bowser.document['#dbmon'],
)
app.call

load_samples = proc do
  # Bowser.window.animation_frame &load_samples
  Bowser.window.delay 0, &load_samples

  app.perform_render 
end
load_samples.call
