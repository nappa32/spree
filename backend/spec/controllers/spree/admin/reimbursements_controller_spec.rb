require 'spec_helper'

describe Spree::Admin::ReimbursementsController do
  stub_authorization!

  let!(:default_refund_reason) do
    Spree::RefundReason.find_or_create_by!(name: Spree::RefundReason::RETURN_PROCESSING_REASON, mutable: false)
  end

  describe '#create' do
    let(:customer_return)  { create(:customer_return, line_items_count: 1) }
    let(:order) { customer_return.order }
    let(:return_item) { customer_return.return_items.first }
    let(:payment) { order.payments.first }

    before do
      customer_return.return_items.map(&:accept!)
    end

    context "nested attributes" do
      let(:reimbursement_params) do
        {
          customer_return_id: customer_return.to_param,
          reimbursement_items_attributes: [
            {
              inventory_unit_id:   return_item.inventory_unit_id,
              return_item_id:      return_item.id,
              exchange_variant_id: return_item.exchange_variant_id,
              pre_tax_amount:      return_item.pre_tax_amount,
            },
          ],
        }
      end

      subject do
        spree_post :create, order_id: order.to_param, reimbursement: reimbursement_params
      end

      it 'creates the reimbursement' do
        expect { subject }.to change { order.reimbursements.count }.by(1)
        expect(assigns(:reimbursement).reimbursement_items.map(&:return_item)).to include(return_item)
      end

      it 'redirects to the edit page' do
        subject
        expect(response).to redirect_to(spree.edit_admin_order_reimbursement_path(order, assigns(:reimbursement)))
      end
    end
  end

  describe "#perform" do
    let(:reimbursement) { create(:reimbursement) }
    let(:customer_return) { reimbursement.customer_return }
    let(:order) { reimbursement.order }
    let(:reimbursement_items) { reimbursement.reimbursement_items }
    let(:return_items) { reimbursement_items.map(&:return_item) }
    let(:payment) { order.payments.first }

    subject do
      spree_post :perform, order_id: order.to_param, id: reimbursement.to_param
    end

    it 'redirects to customer return page' do
      subject
      expect(response).to redirect_to spree.admin_order_reimbursement_path(order, reimbursement)
    end

    it 'performs the reimbursement' do
      expect {
        subject
      }.to change { payment.refunds.count }.by(1)
      expect(payment.refunds.last.amount).to be > 0
      expect(payment.refunds.last.amount).to eq return_items.to_a.sum(&:total)
    end
  end
end
