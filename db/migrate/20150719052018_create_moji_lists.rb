class CreateMojiLists < ActiveRecord::Migration
  def change
    create_table :moji_lists do |t|
      t.string :kanji
      t.string :yomi
      t.text :imgUrl

      t.timestamps
    end
  end
end
