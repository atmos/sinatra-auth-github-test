require "rubygems"
require "bundler/setup"

require 'rack/ssl'
require 'sinatra/auth/github'

module Example
  class BadAuthentication < Sinatra::Base
    get '/unauthenticated' do
      status 403
      <<-EOS
      <h2>Unable to authenticate, sorry bud.</h2>
      <p>#{env['warden'].message}</p>
      EOS
    end
  end

  class SimpleApp < Sinatra::Base
    enable  :sessions
    enable  :raise_errors
    disable :show_exceptions
    enable :inline_templates

    set :github_options, {
      :scope     => 'user',
      :secret    => ENV['GITHUB_CLIENT_SECRET'] || 'test_client_secret',
      :client_id => ENV['GITHUB_CLIENT_ID']     || 'test_client_id'
    }
    register Sinatra::Auth::Github

    get '/' do
      erb :index
    end

    get '/profile' do
      authenticate!
      erb :profile
    end

    get '/login' do
      authenticate!
      redirect '/'
    end

    get '/logout' do
      logout!
      redirect '/'
    end
  end

  def self.app
    @app ||= Rack::Builder.new do
      run SimpleApp
    end
  end
end

use Rack::SSL if ENV['RAILS_ENV'] == "production"
run Example.app

__END__

@@ layout
<html>
  <body>
    <h1>Simple App Example</h1>
    <ul>
      <li><a href='/'>Home</a></li>
      <li><a href='/profile'>View profile</a><% if !env['warden'].authenticated? %> (implicit sign in)<% end %></li>
    <% if authenticated? %>
      <li><a href='/logout'>Sign out</a></li>
    <% else %>
      <li><a href='/login'>Sign in</a> (explicit sign in)</li>
    <% end %>
    </ul>
    <hr />
    <%= yield %>
  </body>
</html>

@@ index
<% if authenticated? %>
  <h2>
    <img src='<%= env['warden'].user.avatar_url %>' />
    Welcome <%= github_user.name %>
  </h2>
<% else %>
  <h2>Welcome stranger</h2>
<% end %>

@@ profile
<h2>Profile</h2>
<dl>
  <dt>Rails Org Member:</dt>
  <dd><%= github_organization_access?('rails') %></dd>
  <dt>Publicized Rails Org Member:</dt>
  <dd><%= github_public_organization_access?('rails') %></dd>
  <dt>Rails Committer Team Member:</dt>
  <dd><%= github_team_access?(632) %></dd>
</dl>
