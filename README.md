# Large Hadron Migrator [![Build Status](https://secure.travis-ci.org/soundcloud/large-hadron-migrator.png)](http://travis-ci.org/soundcloud/large-hadron-migrator)

Rails style database migrations are a useful way to evolve your data schema in
an agile manner. Most Rails projects start like this, and at first, making
changes is fast and easy.

That is until your tables grow to millions of records. At this point, the
locking nature of `ALTER TABLE` may take your site down for an hour or more
while critical tables are migrated. In order to avoid this, developers begin
to design around the problem by introducing join tables or moving the data
into another layer. Development gets less and less agile as tables grow and
grow. To make the problem worse, adding or changing indices to optimize data
access becomes just as difficult.

> Side effects may include black holes and universe implosion.

There are few things that can be done at the server or engine level. It is
possible to change default values in an `ALTER TABLE` without locking the
table. The InnoDB Plugin provides facilities for online index creation, which
is great if you are using this engine, but only solves half the problem.

At SoundCloud we started having migration pains quite a while ago, and after
looking around for third party solutions [0] [1] [2], we decided to create our
own. We called it Large Hadron Migrator, and it is a gem for online
ActiveRecord migrations.

![LHC](http://farm4.static.flickr.com/3093/2844971993_17f2ddf2a8_z.jpg)

[The Large Hadron collider at CERN](http://en.wikipedia.org/wiki/Large_Hadron_Collider)

## The idea

The basic idea is to perform the migration online while the system is live,
without locking the table. In contrast to OAK (online alter table) [0] and the
facebook tool [1], we only use a copy table and triggers.

The Large Hadron is a test driven Ruby solution which can easily be dropped
into an ActiveRecord migration. It presumes a single auto incremented
numerical primary key called id as per the Rails convention. Unlike the
twitter solution [2], it does not require the presence of an indexed
`updated_at` column.

## Usage

You can invoke Lhm directly from a plain ruby file after connecting active
record to your mysql instance:

    require 'lhm'

    ActiveRecord::Base.establish_connection(
      :adapter => 'mysql',
      :host => '127.0.0.1',
      :database => 'lhm'
    )

    Lhm.change_table(:users) do |m|
      m.add_column(:arbitrary, "INT(12)")
      m.add_index([:arbitrary, :created_at])
      m.ddl("alter table %s add column flag tinyint(1)" % m.name)
    end

To use Lhm from an ActiveRecord::Migration in a Rails project, add it to your
Gemfile, then invoke as follows:

    class MigrateUsers < ActiveRecord::Migration

      def self.up
        Lhm.change_table(:users) do |m|
          m.add_column(:arbitrary, "INT(12)")
          m.add_index([:arbitrary, :created_at])
          m.ddl("alter table %s add column flag tinyint(1)" % m.name)
        end
      end

      def self.down
        Lhm.change_table(:users) do |m|
          m.remove_index([:arbitrary, :created_at])
          m.remove_column(:arbitrary)
        end
      end
    end

## Contributing

We'll check out your contribution if you:

- Provide a comprehensive suite of tests for your fork.
- Have a clear and documented rationale for your changes.
- Package these up in a pull request.

We'll do our best to help you out with any contribution issues you may have.

## License

The license is included as LICENSE in this directory.

## Footnotes

[0]: http://openarkkit.googlecode.com "OAK online alter table"
[1]: http://www.facebook.com/note.php?note\_id=430801045932 "Facebook"
[2]: https://github.com/freels/table\_migrator "Twitter"

