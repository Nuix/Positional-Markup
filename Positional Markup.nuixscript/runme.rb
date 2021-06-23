java_import javax.swing.JOptionPane
import javax.swing.JComboBox
import javax.swing.JDialog
import javax.swing.JFrame
import javax.swing.JLabel
import javax.swing.JPanel
import javax.swing.JProgressBar
debug=false

class ProgressDialog < JDialog
	def initialize(settings,title="Progress Dialog")
		@bars=settings
		super nil, true
		body=JPanel.new(java.awt.GridLayout.new(settings.keys.size*2,1))
		settings.each do | label,config|
			body.add(JLabel.new(label))
			progress_stat = JProgressBar.new  config["min"], config["max"]
			body.add(progress_stat)
			@bars[label]=progress_stat
			self.add(body)
		end
		self.setTitle(title)
		self.setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE
		self.setSize 400, settings.keys.size*90
		self.setLocationRelativeTo nil
		Thread.new{
				yield self
			sleep(0.2)
			self.dispose()
		}
		self.setVisible true
	end

	def increment(label)
		@bars[label].setValue(@bars[label].getValue() +1)
	end

	def setValue(label,value=0)
		@bars[label].setValue(value)
	end

	def setMax(label,max)
		@bars[label].setMaximum(max)
	end
end

def show_message(message,title="Message")
	JOptionPane.showMessageDialog(nil,message,title,JOptionPane::PLAIN_MESSAGE)
end

def getComboInput(settings,title)
	if(settings.class!=Hash) 
		raise "settings are expected in Array values, e.g. {\"label\"=>[\"Value1\",\"Value2\"]}"
	end
	panel = JPanel.new(java.awt.GridLayout.new(0,2))
	
	controls=Array.new()
	settings.each do | setting,value|
		lbl=JLabel.new("#{setting}")
		panel.add(lbl)
		cb = JComboBox.new value.to_java
		cb.name=setting
		cb.setFocusable(false)
		panel.add(cb)
		controls.push cb
	end
	JOptionPane.showMessageDialog(JFrame.new, panel,title,JOptionPane::PLAIN_MESSAGE );

	responses=Hash.new()
	controls.each do | control|
		responses[control.name]=control.getSelectedItem.to_s
	end
	return responses
end

options={
	"Markup"=>currentCase.getMarkupSets.map{|r|r.getName},
	"Apply Markup"=>currentCase.getMarkupSets.map{|r|r.getName}.reverse(),
}

options=getComboInput(options,"Options")
pilotMarkup=currentCase.getMarkupSets.select{|r|r.getName()==options["Markup"]}.first()
applyMarkup=currentCase.getMarkupSets.select{|r|r.getName()==options["Apply Markup"]}.first()

pilotItems=currentCase.searchUnsorted('markup-set:"' + pilotMarkup.getName() + '"')

if pilotItems.size()==0
	show_message("No Pilot items with the required markup? Aborting...")
	exit
end
window.closeAllTabs()

pilotPlots={}
hasHighlights=false
pilotItems.each do | pilotItem |
	plots={}
	pilotItem.getPrintedImage().getPages().each_with_index do | myPrintedPage,pageNumber |
		myPrintedPage.getMarkups(pilotMarkup).each do | markup |
			plotMatch={
				"x"=>markup.getX(),
				"y"=>markup.getY(),
				"w"=>markup.getWidth(),
				"h"=>markup.getHeight(),
				"pageNumber"=>pageNumber,
				"highlight"=>markup.isHighlight()
			}
			if(markup.isHighlight())
				plotMatch["text"]=myPrintedPage.getText(plotMatch['x'],plotMatch['y'],plotMatch['w'],plotMatch['h']).strip().to_s
				hasHighlights=true
			end
			plots[markup.getUniqueId]=plotMatch
		end
	end
	pilotPlots[pilotItem.getGuid()]=plots
end

if(!hasHighlights)
	show_message("All pilots have no highlights to validate the redactions? Aborting")
	exit
end

settings={
	"progress"=>{"min"=>0,"max"=>currentSelectedItems.size()},
	"success"=>{"min"=>0,"max"=>currentSelectedItems.size()},
	"fail"=>{"min"=>0,"max"=>currentSelectedItems.size()},
}

failedItems=[]
ProgressDialog.new(settings,"Markup in progress") do | pd |
	currentSelectedItems.each do | item|
		if(item.getPrintedImage().getPages().nil?)
			passedAccuracy=false
		else
			thisPages=item.getPrintedImage().getPages().size()
			itemPages=item.getPrintedImage().getPages()
			itemPages.each do | myPrintedPage |
				myPrintedPage.getMarkups(applyMarkup).each do | existingMarkupItem|
					myPrintedPage.remove(applyMarkup,existingMarkupItem)
				end
			end
			passedAccuracy=true
			pilotPlots.each do | pilotGuid, pilotPlots |
				passedAccuracy=true
				itemPages.each_with_index do | myPrintedPage,pageNumber |
					pilots=pilotPlots.select{|id,plot|(plot["pageNumber"]==pageNumber) && (plot["highlight"]==true)}
					pilots.each do | id,plotMatch |
						text=myPrintedPage.getText(plotMatch['x'],plotMatch['y'],plotMatch['w'],plotMatch['h']).strip().to_s
						if(text!=plotMatch["text"])
							passedAccuracy=false
							if(debug)
								puts item.getGuid() + "\t" + pilotGuid + ": Text at coordinates does not match pilot: Expected '" + plotMatch["text"] + "', Actual '" + text + "'"
							end
							break
						end
					end
					if(!passedAccuracy)
						break
					end
				end
				if(passedAccuracy)
					itemPages.each_with_index do | myPrintedPage,pageNumber |
						pilotPlots.select{|id,plot|(plot["pageNumber"]==pageNumber) && (plot["highlight"]==false)}.each do | id,plotMatch |
							myPrintedPage.createRedaction(applyMarkup,plotMatch['x'],plotMatch['y'],plotMatch['w'],plotMatch['h'])
						end
					end
					break
				end
			end
		end
		pd.increment("progress")
		if(!passedAccuracy)
			pd.increment("fail")
			failedItems.push(item.getGuid())
		else
			pd.increment("success")
		end
	end
	
end
if(failedItems.size() > 0)
	window.openTab("workbench",{"search"=>"guid:(" + failedItems.join(" OR " ) + ")"})
	show_message("Items in this tab are needing new pilots drawn")
else
	show_message("All Items has Markup applied")
end
exit