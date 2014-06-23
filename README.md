# Table Differ

Take snapshots of database tables and compute the differences between two snapshots.

[![Build Status](https://api.travis-ci.org/bronson/tablediffer.png?branch=master)](http://travis-ci.org/bronson/tablediffer)

## Installation

The usual, add this line to your application's Gemfile:

```ruby
gem 'tablediffer'
```

## Usage

Add this line to each model that you want to snapshot:

```ruby
class Property  < ActiveRecord::Base
  include 'table_differ'
  ...
end
```

### Snapshot a Table

Any time you want to snapshot a table (say, before a new import),
call create_snapshot.

```ruby
Property.create_snapshot
Property.create_snapshot 'import_0012'
```

If you don't specify a name for the snapshot, one will be created for you.
To preserve sanity, your snapshot names need to sort alphabetically.

Use the snapshots method to return the snapshots that exist now:

```ruby
Property.snapshots
=> ['property_import_0011', 'property_import_0012']
```

### Compute Differences

Now, to retrieve a list of the differences, call diff:

```ruby
differences = Property.diff      # diff between most recent snapshot and model's table
d2 = Property.diff 'import_0012' # diff between most recent snapshot and named snapshot
d3 = Property.diff 'cc', 'cd'    # difference between two named snapshots
```

### Delete Snapshots

delete_snapshot gets rid of unwanted snapshots.
Either pass a name or a proc to specify which snapshots should be deleted.

```ruby
Property.delete_snapshot 'import_0012'
Property.delete_snapshot { |name| name < Property.snapshot_name(1.week.ago) }
```

## Internals

Table Differ creates a full copy of the table whenever Snapshot is called.
If your tables are very large, this is not the gem for you.
(TODO: could CREATE DATABASE ... TEMPLATE work to create snapshots?)

It diffs the tables server-side using two SELECT queries.  This should
be super fast.


## Contributing

Send issues and pull requests to [Table Differ's Github](github.com/bronson/tablediffer).
