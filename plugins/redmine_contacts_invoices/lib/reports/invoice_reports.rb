# This file is a part of Redmine Invoices (redmine_contacts_invoices) plugin,
# invoicing plugin for Redmine
#
# Copyright (C) 2011-2013 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts_invoices is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts_invoices is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts_invoices.  If not, see <http://www.gnu.org/licenses/>.

module RedmineInvoices
  module InvoiceReports
    class << self
      include Redmine::I18n
      include InvoicesHelper
      include ContactsMoneyHelper

      def invoice_to_pdf_prawn(invoice, type)
        saved_language = User.current.language
        set_language_if_valid(invoice.language || User.current.language)
        s = invoice_to_pdf_classic(invoice)
        set_language_if_valid(saved_language)
        s
      end

      def akt_to_pdf_prawn(invoice, type)
        saved_language = User.current.language
        set_language_if_valid(invoice.language || User.current.language)
        s = akt_to_pdf_classic(invoice)
        set_language_if_valid(saved_language)
        s
      end      

      def invoice_to_pdf_classic(invoice)

        # InvoiceReport.new.to_pdf(invoice)
        pdf = Prawn::Document.new(:info => {
            :Title => "#{l(:label_invoice)} - #{invoice.number}",
            :Author => User.current.name,
            :Producer => InvoicesSettings[:invoices_company_name, invoice.project].to_s,
            :Subject => "Invoice",
            :Keywords => "invoice",
            :Creator => InvoicesSettings[:invoices_company_name, invoice.project].to_s,
            :CreationDate => Time.now,
            :TotalAmount => price_to_currency(invoice.amount, invoice.currency, :converted => false, :symbol => false),
            :TaxAmount => price_to_currency(invoice.tax_amount, invoice.currency, :converted => false, :symbol => false),
            :Discount => price_to_currency(invoice.discount_amount, invoice.currency, :converted => false, :symbol => false)
            },
            :margin => [50, 50, 60, 50])
        contact = invoice.contact || Contact.new(:first_name => '[New client]', :address_attributes => {:street1 => '[New client address]'}, :phone => '[phone]')

        fonts_path = "#{Rails.root}/plugins/redmine_contacts_invoices/lib/fonts/"
        pdf.font_families.update(
               "FreeSans" => { :bold => fonts_path + "FreeSansBold.ttf",
                               :italic => fonts_path + "FreeSansOblique.ttf",
                               :bold_italic => fonts_path + "FreeSansBoldOblique.ttf",
                               :normal => fonts_path + "FreeSans.ttf" })

        # pdf.stroke_bounds
        pdf.font("FreeSans", :size => 9)
        # pdf.font("Times-Roman")
        pdf.default_leading -5
        status_stamp(pdf, invoice)
        #header
        logo_bo_image = Rails.root.to_s +  "/plugins/redmine_contacts_invoices/assets/images/logo_bo.png"
        pdf.image logo_bo_image
        pdf.bounding_box [pdf.bounds.width - 450, pdf.bounds.height + 10], :width => 450 do
          pdf.text InvoicesSettings[:invoices_company_name, invoice.project].to_s, :style => :bold, :size => 18
          pdf.text InvoicesSettings[:invoices_company_representative, invoice.project].to_s if InvoicesSettings[:invoices_company_representative, invoice.project]
          pdf.text_box "#{InvoicesSettings[:invoices_company_info, invoice.project].to_s}",
            :at => [0, pdf.cursor], :width => 140
        end
        #   # pdf.stroke_bounds
        #   pdf.fill_color "cccccc"
        #   pdf.text l(:label_invoice), :align => :right, :style => :bold, :size => 30
        #   # pdf.text_box l(:label_invoice), :at => [pdf.bounds.width - 100, pdf.bounds.height + 10],
        #   #              :style => :bold, :size => 30, :color => 'cccccc', :align => :right, :valign => :top,
        #   #              :width => 100, :height => 50,
        #   #              :overflow => :shrink_to_fit

        #   pdf.fill_color "000000"

        # image = Rails.root.to_s +  "/plugins/redmine_contacts_invoices/assets/images/logo_bo.png"
        # data = [[l(:text_director), {:image => image, :fit => [210, 315]}, l(:text_director_fio)]]
        # pdf.table data, :width => pdf.bounds.width, :column_widths => {0 => 100, 2 => 180}, 
        #                 :cell_style => {:valign => :center} do
        #   cells.borders = []
        #   columns(0).align = :right
        # end 

        pdf.move_down(40)

        pdf.text l(:text_payment_example), :style => :bold, :align => :center
        pdf.move_down(10)

        payment_details(pdf, invoice)
        pdf.move_down(20)

        pdf.text l(:label_invoice) + " N " + invoice.number + " " + 
                 l(:text_from) + " " + format_date(invoice.invoice_date), :style => :bold, 
                 :size => 16, :align => :center
        pdf.move_down(20)    

        pdf.text "#{l(:label_invoice_bill_to)}: #{contact.name}"       
        pdf.move_down(10)

        classic_table(pdf, invoice)
        # if InvoicesSettings[:invoices_bill_info, invoice.project]
        #   pdf.text InvoicesSettings[:invoices_bill_info, invoice.project]
        # end
        pdf.text l(:text_to_pay) + ": " + price_to_currency(invoice.subtotal, invoice.currency, :converted => false, :symbol => false),
                 :style => :bold, :size => 12
        pdf.move_down(10)        
        pdf.text invoice.description
        pdf.move_down(10)
        pdf.text l(:text_no_nds)
        pdf.move_down(10)
        pdf.text l(:text_usn)
        pdf.move_down(10)
        stamp_busation(pdf, invoice)
        pdf.number_pages "<page>/<total>", {:at => [pdf.bounds.right - 150, -10], :width => 150,
                  :align => :right} if pdf.page_number > 1
        pdf.repeat(lambda{ |pg| pg > 1}) do
           pdf.draw_text "##{invoice.number}", :at => [0, -20]
        end

        pdf.render
      end

      def akt_to_pdf_classic(invoice)

        # InvoiceReport.new.to_pdf(invoice)
        pdf = Prawn::Document.new(:info => {
            :Title => "#{l(:label_invoice)} - #{invoice.number}",
            :Author => User.current.name,
            :Producer => InvoicesSettings[:invoices_company_name, invoice.project].to_s,
            :Subject => "Invoice",
            :Keywords => "invoice",
            :Creator => InvoicesSettings[:invoices_company_name, invoice.project].to_s,
            :CreationDate => Time.now,
            :TotalAmount => price_to_currency(invoice.amount, invoice.currency, :converted => false, :symbol => false),
            :TaxAmount => price_to_currency(invoice.tax_amount, invoice.currency, :converted => false, :symbol => false),
            :Discount => price_to_currency(invoice.discount_amount, invoice.currency, :converted => false, :symbol => false)
            },
            :margin => [50, 50, 60, 50])
        contact = invoice.contact || Contact.new(:first_name => '[New client]', :address_attributes => {:street1 => '[New client address]'}, :phone => '[phone]')

        fonts_path = "#{Rails.root}/plugins/redmine_contacts_invoices/lib/fonts/"
        pdf.font_families.update(
               "FreeSans" => { :bold => fonts_path + "FreeSansBold.ttf",
                               :italic => fonts_path + "FreeSansOblique.ttf",
                               :bold_italic => fonts_path + "FreeSansBoldOblique.ttf",
                               :normal => fonts_path + "FreeSans.ttf" })

        # pdf.stroke_bounds
        pdf.font("FreeSans", :size => 9)
        # pdf.font("Times-Roman")
        pdf.default_leading -5
        #header
        logo_bo_image = Rails.root.to_s +  "/plugins/redmine_contacts_invoices/assets/images/logo_bo.png"
        pdf.image logo_bo_image
        pdf.bounding_box [pdf.bounds.width - 450, pdf.bounds.height + 10], :width => 450 do
          pdf.text InvoicesSettings[:invoices_company_name, invoice.project].to_s, :size => 16
          pdf.move_down(5)
          pdf.text InvoicesSettings[:invoices_company_representative, invoice.project].to_s if InvoicesSettings[:invoices_company_representative, invoice.project]
          pdf.text_box "#{InvoicesSettings[:invoices_company_info, invoice.project].to_s}",
            :at => [0, pdf.cursor], :width => 140
        end

        pdf.move_down(40)

        due_date = invoice.due_date ? format_date(invoice.due_date) : ""
        pdf.text l(:label_akt) + " N " + invoice.order_number + " " + 
                 l(:text_from) + " " + due_date, :style => :bold, 
                 :size => 16, :align => :center
        pdf.text l(:text_akt_about), :size => 12, :align => :center         
        pdf.move_down(20)    

        pdf.text l(:text_supplier), :size => 12     
        pdf.move_down(5)
        pdf.text "#{l(:text_customer)}: #{contact.name}", :size => 12    
        pdf.move_down(10)        

        classic_table(pdf, invoice)

        pdf.text l(:text_vsego_uslug) + ": " + invoice.description, :size => 12
        pdf.move_down(10)        
        pdf.text l(:text_no_nds)
        pdf.move_down(10)
        pdf.text l(:text_usn)
        pdf.move_down(20)
        pdf.text l(:text_pretensii_net)
        pdf.move_down(30)        

        data = [ [l(:text_supplier2), l(:text_customer2)],
                 [l(:text_director_bo), "_____________________________________"],
                 ["__________________ " + l(:text_director_fio), "__________________ / __________________"],
                 [l(:text_mp), l(:text_mp)]
               ]
        pdf.table data, :width => pdf.bounds.width,
                        :column_widths => {0 => 250} do
          cells.borders = []
          row(3).style(:padding_left => 80)
        end

        pdf.number_pages "<page>/<total>", {:at => [pdf.bounds.right - 150, -10], :width => 150,
                  :align => :right} if pdf.page_number > 1
        pdf.repeat(lambda{ |pg| pg > 1}) do
           pdf.draw_text "##{invoice.number}", :at => [0, -20]
        end

        pdf.render
      end      

      def status_stamp(pdf, invoice)
        case invoice.status_id
        when Invoice::DRAFT_INVOICE
          stamp_text = "DRAFT"
          stamp_color = "993333"
        when Invoice::PAID_INVOICE
          stamp_text = "PAID"
          stamp_color = "1e9237"
        else
          stamp_text = ""
          stamp_color = "1e9237"
        end

        stamp_text_width = pdf.width_of(stamp_text, :font => "Times-Roman", :style => :bold, :size => 120)
        pdf.create_stamp("draft") do
          pdf.rotate(30, :origin => [0, 50]) do
            pdf.fill_color stamp_color
            pdf.font("Times-Roman", :style => :bold, :size => 120) do
              pdf.transparent(0.08) {pdf.draw_text stamp_text, :at => [0, 0]}
            end
            pdf.fill_color "000000"
          end
        end

        pdf.stamp_at "draft", [(pdf.bounds.width / 2) - stamp_text_width / 2, (pdf.bounds.height / 2) ] unless stamp_text.blank?
      end

      def payment_details(pdf, invoice)
        data = [ [l(:text_reciever), "", ""],
                 [l(:text_reciever_rekv), l(:text_account), l(:text_account_rekv)],
                 [l(:text_bank), l(:text_bik), l(:text_bik_rekv)],
                 [l(:text_bank_rekv), l(:text_account), l(:text_bank_account_rekv)]
               ]
        pdf.table data, :width => pdf.bounds.width, :cell_style => {:padding => [-3, 5, 3, 5]},
                        :column_widths => {1 => 40, 2 => 120} do
          cells.borders = []
          row(0).borders = [:top, :right, :left]
          row(1).borders = [:right, :left]
          row(2).borders = [:top, :right, :left]
          row(3).borders = [:bottom, :right, :left]
          row(3).columns(1).borders = [:top, :bottom, :right, :left]
        end
      end

      def classic_table(pdf, invoice)
        lines = invoice.lines.map do |line|
          [
            line.position,
            line.description,
            "x#{invoice_number_format(line.quantity)}",
            line.units,
            price_to_currency(line.price, invoice.currency, :converted => false, :symbol => false),
            price_to_currency(line.total, invoice.currency, :converted => false, :symbol => false)
          ]
        end
        lines.insert(0,[l(:field_invoice_line_position),
                       l(:field_invoice_line_description),
                       l(:field_invoice_line_quantity),
                       l(:field_invoice_line_units),
                       label_with_currency(:field_invoice_line_price, invoice.currency),
                       label_with_currency(:label_invoice_total, invoice.currency) ])
        lines << ['']
        lines << ['', '', '', '', l(:label_invoice_sub_amount) + ":", price_to_currency(invoice.subtotal, invoice.currency, :converted => false, :symbol => false)]  if invoice.discount_amount > 0 || (invoice.tax_amount> 0 && !invoice.total_with_tax?)

        invoice.tax_groups.each do |tax_group|
          lines << ['', '', '', '', "#{l(:label_invoice_tax)} (#{invoice_number_format(tax_group[0])}%):", price_to_currency(tax_group[1], invoice.currency, :converted => false, :symbol => false)]
        end if invoice.tax_amount> 0

        lines << ['', '', '', '', discount_label(invoice) + ":", "-" + price_to_currency(invoice.discount_amount, invoice.currency, :converted => false, :symbol => false)] if invoice.discount_amount > 0

        lines << ['', '', '', '', label_with_currency(:label_invoice_total, invoice.currency) + ":", price_to_currency(invoice.amount, invoice.currency, :converted => false, :symbol => false)]

        pdf.table lines, :width => pdf.bounds.width, :cell_style => {:padding => [-3, 5, 3, 5]}, :header => true do |t|
          # t.cells.padding = 405
          t.columns(0).width = 20
          t.columns(2).align = :center
          t.columns(2).width = 40
          t.columns(3).align = :center
          t.columns(3).width = 50
          t.columns(4..5).align = :right
          t.columns(4..5).width = 90
          t.row(0).font_style = :bold
          t.row(0).align = :center
          # t.row(0).background_color = 'cccccc'

          max_width =  t.columns(2).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(2).width = max_width if max_width < 100

          max_width =  t.columns(3).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(3).width = max_width if max_width < 100

          max_width =  t.columns(4).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(4).width = max_width if max_width < 120

          max_width =  t.columns(5).inject(0) { |width, cell| [width, pdf.width_of(cell.content, :style => :bold) + 15].max }
          t.columns(5).width = max_width if max_width < 120


          t.row(invoice.lines.count + 2).padding = [5, 5, 3, 5]

          t.row(invoice.lines.count + 2..invoice.lines.count + 6).borders = []
          t.row(invoice.lines.count + 2..invoice.lines.count + 6).font_style = :bold
        end
      end

      def stamp_busation(pdf, invoice)
        image = Rails.root.to_s +  "/plugins/redmine_contacts_invoices/assets/images/stamp_bo.png"
        data = [[l(:text_director), {:image => image, :fit => [210, 315]}, l(:text_director_fio)]]
        pdf.table data, :width => pdf.bounds.width, :column_widths => {0 => 100, 2 => 180}, 
                        :cell_style => {:valign => :center} do
          cells.borders = []
          columns(0).align = :right
        end          
      end
    end
  end
end
