require 'bundler'
Bundler.require

require 'unirest'
require 'pry'
require 'active_support/core_ext/hash'
require 'tty-prompt'
require 'tty-table'
require 'tty-spinner'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.db')
require_all 'app'
require_all 'app/models'

old_logger = ActiveRecord::Base.logger
ActiveRecord::Base.logger = nil