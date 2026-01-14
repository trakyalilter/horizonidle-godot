extends PanelContainer

@onready var report_label = $MarginContainer/VBoxContainer/ReportLabel
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	visible = false

func check_and_show():
	if GameState.offline_report and GameState.offline_report != "":
		show_report(GameState.offline_report)
		GameState.offline_report = "" # Clear it

func show_report(text: String):
	report_label.text = text
	visible = true
	
func _on_ack_btn_pressed():
	visible = false
