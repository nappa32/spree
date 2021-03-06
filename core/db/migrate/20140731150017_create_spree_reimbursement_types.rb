class CreateSpreeReimbursementTypes < ActiveRecord::Migration
  def change
    create_table :spree_reimbursement_types do |t|
      t.string :name
      t.boolean :active, default: true
      t.boolean :mutable, default: true

      t.timestamps
    end

    Spree::ReimbursementType.create!(name: Spree::ReimbursementType::ORIGINAL)

    add_column :spree_return_items, :preferred_reimbursement_type_id, :integer
  end
end
