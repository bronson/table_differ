# Table Differ

Take snapshots of database tables and compute the differences between two snapshots.

[![Build Status](https://api.travis-ci.org/bronson/tablediffer.png?branch=master)](http://travis-ci.org/bronson/tablediffer)

## Installation

The usual, add this line to your application's Gemfile:

```ruby
gem 'tablediffer'
```

## Usage

Add this line to the models that will be snapshotted:

```ruby
class Property  < ActiveRecord::Base
  include TableDiffer
  ...
end
```

### Snapshot a Table

Any time you want to snapshot a table (say, before a new import),
call `create_snapshot`.

```ruby
Property.create_snapshot
Property.create_snapshot 'import_0012'
```

If you don't specify a name then a numeric name based on the current
date will be used (property_20140606_124722)
To preserve your sanity, make sure snapshot names sort alphabetically.

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

#### Columns to Ignore

By default, every column will be considered in the diff.
You can pass columns to ignore like this:

```ruby
Property.diff_snapshot ignore: %w[ id created_at updated_at ]
```

Note that if you ignore the primary key, tablediffer can no longer compute which
columns have changed.  Changed records will appear as a simultaneous add and remove,
and the changed column will always be empty.  In those cases, just call it like this:

```ruby
added,removed = Attachment.diff_snapshot(ignore: 'id')
```

Also, if you ignore the ID, you won't be able to update or save any records directly
(since, of course, they won't know their IDs).

#### Specifying the Snapshot

You can name the tables you want to diff explicitly:

```ruby
a,r,c = Property.diff_snapshot(old: 'import_0012')   # changes between the named snapshot and now
a,r,c = Property.diff_snapshot('cc', 'cd')           # difference between the two named snapshots
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
If your tables are very large, this is not the gem for you.

It diffs the tables server-side using two SELECT queries.  This should
be super fast.


## Contributing

Send issues and pull requests to [Table Differ's Github](github.com/bronson/tablediffer).
