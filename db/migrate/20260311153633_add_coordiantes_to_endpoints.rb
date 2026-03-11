class AddCoordiantesToEndpoints < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL)
      CREATE FUNCTION public.hashpoint(point) RETURNS integer
        LANGUAGE sql IMMUTABLE
        AS 'SELECT hashfloat8($1[0]) # hashfloat8($1[1])';
    SQL

    execute(<<~SQL)
      CREATE OPERATOR CLASS public.point_hash_ops DEFAULT FOR TYPE point USING hash AS
        OPERATOR 1 ~=(point,point),
        FUNCTION 1 public.hashpoint(point);
    SQL

    add_column :endpoints, :coordinates, :point
  end

  def down
    remove_column :endpoints, :coordinates

    execute("DROP OPERATOR CLASS public.point_hash_ops USING hash")
    execute("DROP FUNCTION public.hashpoint(point)")
  end
end
