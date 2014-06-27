# Table Differ

Take snapshots of database tables and compute the differences between two snapshots.

[![Build Status](https://api.travis-ci.org/bronson/table_differ.png?branch=master)](http://travis-ci.org/bronson/table_differ)

## Installation

The usual, add this line to your application's Gemfile:

```ruby
gem 'table_differ'
```

## Usage

Include TableDiffer in models that will be snapshotted:

```ruby
class Property  < ActiveRecord::Base
  include TableDiffer
  ...
end
```

### Snapshot a Table

Any time you want to snapshot a table (say, before a new data import),
call `create_snapshot`.

```ruby
Property.create_snapshot
Property.create_snapshot 'import_0012'
```

If you don't specify a name then a numeric name based on the current
date will be used (something like `property_20140606_124722`)
Whatever naming scheme you use, the names need to sort alphabetically so
Table Differ can know which one is most recent.

Use the snapshots method to return all the snapshots that exist now:

```ruby
Property.snapshots
=> ['property_import_0011', 'property_import_0012']
```

### Compute Differences

Now, to retrieve a list of the differences, call diff_snapshot:

```ruby
added,removed,changed = Property.diff_snapshot
```

This computes the difference between the current table and the most recent
snapshot (determined alphabetically).  Each value is an array of ActiveRecord
objects.  `added` contains the records that have been added since the snapshot
was taken, `removed` contains the records that were removed, and `changed` contains
records where, of course, one or more of their columns have changed.  Tablediffer
doesn't follow foreign keys so, if you want that, you'll need to do it manually.

Records in `added` and `changed` are regular ActiveRecord objects -- you can modify
their attributes and save them.  Records in `removed`, however, aren't backed by
a database object and should be treated read-only.

Changed records include a hash of the original attributes before the change was
made.  For example, if you changed the name column from 'Nexus' to 'Nexii':

```ruby
record.attributes
=> { 'id' => 1, 'name' => 'Nexus' }
record.original_attributes
=> { 'name' => 'Nexii' }   # id didn't change
```

Single-Table Inheritance (STI) appears to work correctly (TODO: add this to tests!)


#### Columns to Ignore

By default, every column will be considered in the diff.
You can pass columns to ignore like this:

```ruby
Property.diff_snapshot ignore: %w[ id created_at updated_at ]
```

Note that if you ignore the primary key, Table Differ can no longer compute which
columns have changed.  Changed records will appear as a remove followed by an add,
so you can ignore the empty third array.

```ruby
added,removed = Attachment.diff_snapshot(ignore: 'id')
```

Also, if you ignore the ID, you won't be able to update or save any models directly.
You must copy the attributes to another model, one that was loaded from the database
normally and still knows its ID.

#### Specifying the Snapshot

You can name the tables you want to diff explicitly:

```ruby
a,r,c = Property.diff_snapshot(old: 'import_0012')   # changes between the named snapshot and now
a,r,c = Property.diff_snapshot('cc', 'cd')           # difference between the two snapshots named cc and cd
```

### Delete Snapshots

delete_snapshot gets rid of unwanted snapshots.
Either pass a name or a proc to specify which snapshots should be deleted.

```ruby
Property.delete_snapshot 'import_0012'

week_old_name = Property.snapshot_name(1.week.ago)
old_snapshots = Property.snapshots.select { |name| name < week_old_name }
Property.delete_snapshots(old_snapshots)
```

## Internals

Table Differ creates a full copy of the table whenever Snapshot is called.
If your table is large enough that it would cause problems if it suddenly
doubled in size, then this is not the gem for you.

Table Differ diffs the tables server-side using only two SELECT queries.
This should be plenty fast for any normal usage.


## Contributing

Send issues and pull requests to [Table Differ's Github](github.com/bronson/table_differ).
