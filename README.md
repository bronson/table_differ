# Table Differ

Snapshot database tables, restore them, and compute the differences between two snapshots.

[![Build Status](https://api.travis-ci.org/bronson/table_differ.png?branch=master)](http://travis-ci.org/bronson/table_differ)
[![Gem Version](https://badge.fury.io/rb/table_differ.svg)](http://badge.fury.io/rb/table_differ)

## Installation

The usual, add this line to your application's Gemfile:

```ruby
gem 'table_differ'
```

## Synopsis

To follow this, replace `Attachment` with any model from your own application.
Once you restore the snapshot, your database should appear unchanged.

```ruby
snapshot = Attachment.create_snapshot
Attachment.first.update_attributes!(name: 'newname')    # make a change
#     or run rake db:migrate, Attachment.delete_all, or anything.

# compute the changes
added,removed,changed = Attachment.diff_snapshot(snapshot)
  => [[], [], [<Attachment 1>]]

Attachment.restore_snapshot(snapshot)
Attachment.delete_snapshot(snapshot)
# and we're right back where we started
```

## Usage

Include TableDiffer in models that will be snapshotted:

```ruby
class Attachment  < ActiveRecord::Base
  include TableDiffer
  ...
end
```

### Create Snapshot

```ruby
Property.create_snapshot
Property.create_snapshot 'import_0012'
```

If you don't specify a name then one will be specified for you.
Whatever naming scheme you use, the names should sort alphabetically.
Otherwise some Table Differ functions won't be able to default to the most recent snapshot.

### List Snapshots

```ruby
Property.snapshots
=> ['property_import_0011', 'property_import_0012']
```

### Restore Snapshot

```ruby
Property.restore_snapshot 'import_0012'
```

### Delete Snapshots

```ruby
Property.delete_snapshot  'import_0012'
```

Or multiple snapshots:

```ruby
Property.delete_snapshots  ['import_01', 'import_02']
Property.delete_snapshots  # deletes all Property snapshots

# more complex: delete all snapshots more than one week old
week_old_name = Property.snapshot_name(1.week.ago)
Property.delete_snapshots { |name| name < week_old_name }
```

### Compute Differences

Now, to retrieve a list of the differences, call diff_snapshot:

```ruby
added,removed,changed = Attachment.diff_snapshot      # compute the change
  => [[], [], [<Attachment 1>]]
changed.first.original_attributes    # returns original value for each field
  => {"name" => 'oldname'}
```

This computes the difference between the current table and the most recent
snapshot (determined alphabetically).  Each value is an array of ActiveRecord
objects.  `added` contains the records that have been added since the snapshot
was taken, `removed` contains the records that were removed, and `changed` contains
records where, of course, one or more of their columns have changed.  Table Differ
doesn't follow foreign keys for that would be madness.  If you want to discover
changes in related tables, you'll need to snapshot and diff them one by one.

Records in `added` and `changed` are regular ActiveRecord objects -- you can modify
their attributes and save them.  Records in `removed`, however, aren't backed by
a database object (obviously) and should be treated read-only.

Changed records include a hash of the original attributes before the change was
made.  For example, if you changed the name column from 'Nexus' to 'Nexii':

```ruby
record.attributes
=> { 'id' => 1, 'name' => 'Nexus' }
record.original_attributes
=> { 'id' => 1, 'name' => 'Nexii' }
```

Single-Table Inheritance (STI) appears to work correctly (TODO: add this to tests!)


#### Columns to Ignore

By default, every column will be considered in the diff.
You can pass columns to ignore like this:

```ruby
Property.diff_snapshot ignore: %w[ id created_at updated_at ]
```

Note that if you ignore the primary key, Table Differ can no longer compute which
columns have changed.  This is no problem, but changed records will appear as a
remove followed by an add.  The changed array will always be empty.

```ruby
added,removed = Attachment.diff_snapshot(ignore: 'id')
```

If there are other fields that uniquely identify the records,
you can specify them in the unique_by option.  This will cause changes to
be computed, and the ActiveRecord objects returned are
complete with IDs.  This requires one database lookup per returned object,
however so, if your results are large, this might not be a good idea.

```ruby
# Normally ingoring the ID prevents diff from being able to compute the changed records.
# If we can use one or more fields to uniquely identify the object,
# then changesets can be computed and full ActiveRecord objects will be returned.
added,removed,changed = Contact.diff_snapshot(ignore: 'id', unique_by: [:property_id, :contact_id])
```

Also, if you ignore the ID, you won't be able to update or save any models directly.
You must copy the attributes to another model, one that was loaded from the database
normally and still knows its ID.

#### Specifying the Snapshot

You can name the tables you want to diff explicitly:

```ruby
add,del,ch = Property.diff_snapshot(old: 'import_0012')   # differences between the named snapshot and the table
add,del,ch = Property.diff_snapshot('cc', 'cd')           # differences between the snapshots named cc and cd
```

## Internals

Table Differ creates a full copy of the table whenever Snapshot is called.
If your table is large enough that it would cause problems if it suddenly
doubled in size, then this is not the gem for you.

Table Differ creates and restores snapshots with a single CREATE/SELECT statement,
and it diffs the tables 100% server-side using two SELECTs.  It should be fast
enough.

It doesn't touch indicies.


## Alternatives

* [Stellar](https://github.com/fastmonkeys/stellar) appears to do the same thing, written in Python.


## Contributing

Send issues and pull requests to [Table Differ's Github](github.com/bronson/table_differ).
