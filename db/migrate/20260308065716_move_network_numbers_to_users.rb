class MoveNetworkNumbersToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :network_ranges, :int4range, array: true, null: false, default: []
    add_index :users, :network_ranges, using: :gin

    update(<<~SQL)
      WITH sorted AS (
        SELECT zones.user_id, lower(r) AS lo, upper(r) AS hi
        FROM zones, unnest(zones.network_ranges) AS r
        ORDER BY zones.user_id, lower(r)
      ),
      islands AS (
        SELECT user_id, lo, hi,
          -- mark a new group whenever there's a gap (not adjacent, not overlapping)
          sum(CASE WHEN lo > prev_hi + 1 OR t.prev_hi IS NULL THEN 1 ELSE 0 END)
            OVER (PARTITION BY user_id ORDER BY lo) AS grp
        FROM (
          SELECT user_id, lo, hi,
                 lag(hi) OVER (partition by user_id ORDER BY lo) AS prev_hi
          FROM sorted
        ) t
      ),
      normalized_by_user as (
        SELECT user_id, int4range(min(lo), max(hi), '[]') AS merged_range
        FROM   islands
        GROUP BY user_id, grp
        ORDER BY user_id, grp
      ),
      grouped_by_user AS (
        SELECT user_id, array_agg(merged_range) AS merged_ranges
        FROM normalized_by_user
        GROUP BY user_id
      )
      UPDATE users SET network_ranges = merged_ranges
      FROM grouped_by_user
      WHERE users.id = grouped_by_user.user_id
    SQL

    remove_column :zones, :network_ranges
  end

  def down
    add_column :zones, :network_ranges, :int4range, array: true, null: false, default: []
    add_index :zones, :network_ranges, using: :gin

    # can't disaggregate, so just copy to all zones and hope for the best
    update(<<~SQL)
      UPDATE zones SET network_ranges = users.network_ranges
      FROM users
      WHERE users.id = zones.user_id
    SQL

    remove_column :users, :network_ranges
  end
end
