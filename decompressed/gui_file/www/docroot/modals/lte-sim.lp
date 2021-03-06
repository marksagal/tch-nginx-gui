--pretranslated: do not change this file
 ngx.print('<style>\
	.float-left {\
		float: left;\
		margin-right: 5px;\
	}\
</style>\
');  
local ngx, tinsert = ngx, table.insert

-- Enable localization
gettext.textdomain('webui-mobiled')

local utils = require("web.lte-utils")
local ui_helper = require("web.ui_helper")
local post_helper = require("web.post_helper")
local content_helper = require("web.content_helper")

local params = utils.get_params()

local mapParams = {
	store_pin = "uci.mobiled.globals.store_pin"
}
local mapValid = {
	store_pin = post_helper.validateBoolean
}
local content = post_helper.handleQuery(mapParams, mapValid)
if not content["store_pin"] or content["store_pin"] == "" then
	content["store_pin"] = "1"
end

local sim = utils.getContent("rpc.mobiled.device.@1.sim.")

ngx.print(ui_helper.createHeader(params.modal_title, true, true, nil))

ngx.print('<div class="modal-body update" id="lte-sim-body">')

ngx.print('<form class="form-horizontal" method="post" action="modals/lte-sim.lp">')

local lp = require("web.lp")
lp.setpath("/www/snippets/")
lp.include("tabs-mobiled.lp")

local html = {}

local pin_error = {
	alert = {
		class = "alert-error hide",
		id = "pin-error-msg"
	}
}

local advanced = {
	group = {
		class = "advanced hide"
	},
	span = {
		class = "span5"
	}
}

local button_class = {
	button = {
		class = "custom-handler"
	}
}

local alert_class = {
	alert = {
		class = "alert hide",
	}
}

local pin_input = {
	input = {
		class = "no-save"
	},
	group = {
		class = "hide"
	}
}

if sim.sim_state == "ready" or sim.sim_state == "locked" or sim.sim_state == "blocked" then
	local option = {}
	option['data-bind'] = "text: pinStateReadable"
	option['class'] = "span5"
	local options = {span = option}

	tinsert(html, '<div data-bind="visible: simViewState() != \'permanently_blocked\'">')

	tinsert(html, "<fieldset><legend>" .. T"PIN Protection" .. "</legend>")

	tinsert(html, ui_helper.createAlertBlock("", pin_error))

	tinsert(html, '<div data-bind="visible: simViewState() == \'default\'">')

	tinsert(html, '<div style="height: 40px;" data-bind="visible: pinState() != \'blocked\'">')

	tinsert(html, '<div data-bind="visible: pinState() == \'locked\'">')
	button_class.button.id = "btn-unlock-pin"
	tinsert(html, ui_helper.createButton(T"Unlock PIN", T"Unlock", "icon-bolt", button_class))
	tinsert(html, '</div>')

	tinsert(html, '<div data-bind="visible: pinState() == \'disabled\'">')
	button_class.button.id = "btn-enable-pin"
	tinsert(html, ui_helper.createButton(T"Enable PIN", T"Enable", "icon-bolt", button_class))
	tinsert(html, '</div>')

	tinsert(html, '<div data-bind="visible: pinState() == \'unlocked\'">')
	button_class.button.id = "grp-disable-pin"
	tinsert(html, ui_helper.createButton(T"Disable PIN", T"Disable", "icon-bolt", button_class))
	button_class.button.id = "grp-change-pin"
	tinsert(html, ui_helper.createButton(T"Change PIN", T"Change", "icon-bolt", button_class))
	tinsert(html, '</div>')
	tinsert(html, '</div>') -- pinState() != 'blocked'

	tinsert(html, '<div data-bind="visible: pinState() == \'blocked\'">')
	button_class.button.id = "btn-unblock-pin"
	tinsert(html, ui_helper.createButton(T"Unblock PIN", T"Unblock", "icon-bolt", button_class))
	tinsert(html, '</div>') -- pinState() == 'blocked'
	tinsert(html, '</div>') -- simViewState() == 'default'

	alert_class.alert.id = "resetting-msg"
	tinsert(html, ui_helper.createAlertBlock(T"Please note that you are disabling the PIN code", alert_class))
	alert_class.alert.id = "changing-msg"
	tinsert(html, ui_helper.createAlertBlock(T"Please note that you are changing the PIN code", alert_class))
	tinsert(html, string.format('<div class="control-group controls">'))
	pin_input.group.id = "pin-code"
	tinsert(html, ui_helper.createInputPassword(T"PIN", "pin", nil, pin_input))
	pin_input.group.id = "newpin-code"
	tinsert(html, ui_helper.createInputPassword(T"New PIN", "newpin", nil, pin_input))
	pin_input.group.id = "rnewpin-code"
	tinsert(html, ui_helper.createInputPassword(T"Confirm new PIN", "rnewpin", nil, pin_input))
	pin_input.group.id = "puk-code"
	tinsert(html, ui_helper.createInputPassword(T"PUK", "puk", nil, pin_input))
	tinsert(html, string.format([[
	      <div id="reset-changes" class="hide">
	      <div id="reset-confirm" class="btn btn-primary">%s</div>
	      <div id="reset-cancel" class="btn">%s</div>
	      </div>
	</div>
	]], T"Confirm", T"Cancel"))

	tinsert(html, '<div style="clear: both;" data-bind="visible: simViewState() == \'default\'">')
	tinsert(html, ui_helper.createSwitch(T"Store PIN", "store_pin", content["store_pin"]))
	tinsert(html, '<div data-bind="visible: pinStateReadable().length > 0">')
	tinsert(html, ui_helper.createLabel(T"Status"..":", "", options))
	tinsert(html, '</div>')
	option['data-bind'] = "text: pinRetriesLeft"
	tinsert(html, ui_helper.createLabel(T"Unlock Retries Left"..":", "", options))
	option['data-bind'] = "text: pukRetriesLeft"
	tinsert(html, ui_helper.createLabel(T"Unblock Retries Left"..":", "", options))
	tinsert(html, '</div>') -- simViewState() == 'default'

	tinsert(html, "</fieldset>")
	tinsert(html, '</div>') -- simViewState() != 'permanently_blocked'

	tinsert(html, "<fieldset><legend>" .. T"SIM Card" .. "</legend>")

	tinsert(html, '<div data-bind="visible: simViewState() == \'permanently_blocked\'">')
	tinsert(html, ui_helper.createAlertBlock(T"SIM Permanently Blocked"))
	tinsert(html, '</div>') -- simViewState() == 'permanently_blocked'

	if sim.iccid ~= "" then
		tinsert(html, ui_helper.createLabel(T"ICCID"..":", sim.iccid))
	end

	if sim.msisdn ~= "" then
		tinsert(html, ui_helper.createLabel(T"MSISDN"..":", sim.msisdn))
	end

	advanced['span']['data-bind'] = "text: imsi"
	tinsert(html, '<div data-bind="visible: imsi().length > 0">')
	tinsert(html, ui_helper.createLabel(T"IMSI"..":", "", advanced))
	tinsert(html, '</div>')
	tinsert(html, "</fieldset>")
else
	local mobiled = {
		num_devices = "rpc.mobiled.DeviceNumberOfEntries"
	}
	content_helper.getExactContent(mobiled)
	mobiled.num_devices = tonumber(mobiled.num_devices)
	if not mobiled.num_devices or mobiled.num_devices == 0 then
		tinsert(html, ui_helper.createAlertBlock(utils.string_map["no_device"]))
	else
		tinsert(html, ui_helper.createAlertBlock(T"SIM Not Present"))
	end
end

ngx.print(html)
ngx.print('</form></div>')
ngx.print(ui_helper.createFooter())
  ngx.print('\
\
<script>\
	$(document).ready(function() {\
		var pin_error_msg = "');  ngx.print( T"The PIN code must be composed of 4 to 8 digits." ); ngx.print('";\
		var new_error_msg = "');  ngx.print( T"Please enter a valid PIN." ); ngx.print('"+" "+pin_error_msg;\
		var rnew_error_msg = "');  ngx.print( T"New PIN code and confirmed PIN code don't match." ); ngx.print('";\
\
		var id = window.setTimeout(function() {}, 0);\
		while (id--) {\
			window.clearTimeout(id);\
		}\
\
		function validatePin(code) {\
			return /^\\d{4,8}$/.test(code);\
		}\
\
		function showError(selector, msg) {\
			$(selector).text(msg);\
			$(selector).removeClass(\'hide\');\
		}\
\
		function editError(selector, msg) {\
			$(selector).text(msg);\
		}\
\
		function hideError(selector) {\
			$(selector).addClass(\'hide\');\
		}\
\
		var simView = function () {\
			var pin = "";\
			var newpin = "";\
			var result = true;\
			var state = "";\
			var self = this;\
			this.imsi = ko.observable("");\
			this.pinStateReadable = ko.observable("");\
			this.pinRetriesLeft = ko.observable("");\
			this.pukRetriesLeft = ko.observable("");\
			this.pinState = ko.observable("");\
			this.simViewState = ko.observable("default");\
			this.setSimView = function(state) {\
				$("input[name=\'pin\']").val(\'\');\
				$("input[name=\'puk\']").val(\'\');\
				$("input[name=\'newpin\']").val(\'\');\
				$("input[name=\'rnewpin\']").val(\'\');\
				$("#pin-code").addClass("hide");\
				$("#newpin-code").addClass("hide");\
				$("#rnewpin-code").addClass("hide");\
				$("#puk-code").addClass("hide");\
				$("#changing-msg").addClass("hide");\
				$("#resetting-msg").addClass("hide");\
				$("#reset-changes").addClass("hide");\
				if (state == "default" && self.pinState() == "unlocked") {\
					$("#grp-change-pin").removeClass("hide");\
					$("#grp-disable-pin").removeClass("hide");\
				}\
				hideError(\'#pin-error-msg\');\
				this.simViewState(state);\
			};\
			this.doChangePin = function() {\
				var rnewpin = $("input[name=\'rnewpin\']").val();\
				this.pin = $("input[name=\'pin\']").val();\
				this.newpin = $("input[name=\'newpin\']").val();\
				if(validatePin(this.pin) && validatePin(this.newpin) && validatePin(rnewpin)) {\
					if (this.newpin != rnewpin) {\
							editError(\'#pin-error-msg\', rnew_error_msg);\
							return false;\
					}\
				} else {\
					editError(\'#pin-error-msg\', new_error_msg);\
					return false;\
				}\
				var params = [{ name: "action", value: "change"},\
							{ name: "old_pin", value: this.pin},\
							{ name: "new_pin", value: this.newpin},\
							tch.elementCSRFtoken()];\
				$.post("/ajax/sim.lua", params, self.updateView, \'json\');\
			};\
			this.setPinState = function(state) {\
				var pin = $("input[name=\'pin\']").val();\
				var params = [{ name: "action", value: state},\
							{ name: "pin", value: pin},\
							tch.elementCSRFtoken()];\
				$.post("/ajax/sim.lua", params, self.updateView, \'json\');\
			};\
			this.unlockPin = function() {\
				var pin = $("input[name=\'pin\']").val();\
				var params = [{ name: "action", value: "unlock"},\
							{ name: "pin", value: pin},\
							tch.elementCSRFtoken()];\
				$.post("/ajax/sim.lua", params, self.updateView, \'json\');\
			};\
			this.unblockPin = function() {\
				var params = [{ name: "action", value: "unblock"},\
							{ name: "pin", value: $("input[name=\'newpin\']").val()},\
							{ name: "puk", value: $("input[name=\'puk\']").val()},\
							tch.elementCSRFtoken()];\
				$.post("/ajax/sim.lua", params, self.updateView, \'json\');\
			};\
			this.refresh = function() {\
				var params = [{ name: "action", value: "default"},\
				tch.elementCSRFtoken()];\
				$.post("/ajax/sim.lua", params, self.updateView, \'json\');\
			};\
			this.updatePinInfo = function(pinInfo) {\
				if(pinInfo.unblock_retries_left != undefined) {\
					self.pukRetriesLeft(pinInfo.unblock_retries_left);\
				}\
				if(pinInfo.unlock_retries_left != undefined) {\
					self.pinRetriesLeft(pinInfo.unlock_retries_left);\
				}\
				if(pinInfo.pin_state != undefined) {\
					if(pinInfo.pin_state == "enabled_not_verified") {\
						self.pinState("locked");\
					} else if(pinInfo.pin_state == "permanently_blocked") {\
						self.pinState("permanently_blocked");\
					} else if(pinInfo.pin_state == "blocked") {\
						self.pinState("blocked");\
					} else if(pinInfo.pin_state == "disabled") {\
						self.pinState("disabled");\
					} else {\
						self.pinState("unlocked");\
					}\
				}\
				if(pinInfo.pin_state_hr != undefined) {\
					self.pinStateReadable(pinInfo.pin_state_hr);\
				} \
			};\
			this.updateSimInfo = function(simInfo) {\
				if(simInfo.imsi != undefined) {\
					self.imsi(simInfo.imsi);\
				}\
			};\
			this.updateView = function(data) {\
				if(data.status != undefined) {\
					this.state = self.simViewState();\
					if(data.pin_info != undefined) {\
						self.updatePinInfo(data.pin_info);\
					}\
					if(data.sim_info != undefined) {\
						self.updateSimInfo(data.sim_info);\
					}\
					if(data.status == false) {\
						if (data.error) {\
							showError(\'#pin-error-msg\', data.error);\
							$("input[name=\'pin\']").val(\'\');\
							$("input[name=\'puk\']").val(\'\');\
							$("input[name=\'newpin\']").val(\'\');\
							$("input[name=\'rnewpin\']").val(\'\');\
						}\
						if (this.state != "unblock" && data.pin_info.pin_state == "blocked") {\
							self.setSimView("default");\
						}\
					} else {\
						if(self.pinState() == "permanently_blocked") {\
							self.setSimView("permanently_blocked");\
						} else {\
							self.setSimView("default");\
						}\
					}\
				}\
			};\
			$("#grp-disable-pin").on("click", function() {\
					self.setSimView("disable");\
					$("#grp-change-pin").addClass("hide");\
					$("#pin-code").removeClass("hide");\
					$("#reset-changes").removeClass("hide");\
					$("#resetting-msg").removeClass("hide");\
			});\
			$("#grp-change-pin").on("click", function() {\
					self.setSimView("change");\
					$("#grp-disable-pin").addClass("hide");\
					$("#pin-code").removeClass("hide");\
					$("#newpin-code").removeClass("hide");\
					$("#rnewpin-code").removeClass("hide");\
					$("#reset-changes").removeClass("hide");\
					$("#changing-msg").removeClass("hide");\
			});\
			$("#btn-unblock-pin").on("click", function() {\
					self.setSimView("unblock");\
					$("#newpin-code").removeClass("hide");\
					$("#puk-code").removeClass("hide");\
					$("#reset-changes").removeClass("hide");\
			});\
			$("#btn-unlock-pin").on("click", function() {\
					self.setSimView("unlock");\
					$("#pin-code").removeClass("hide");\
					$("#reset-changes").removeClass("hide");\
			});\
			$("#btn-enable-pin").on("click", function() {\
					self.setSimView("enable");\
					$("#pin-code").removeClass("hide");\
					$("#reset-changes").removeClass("hide");\
			});\
			$("#reset-confirm").on("click", function() {\
				this.state = self.simViewState();\
				if(this.state == "disable") {\
					self.setPinState("disable");\
				}\
				if(this.state == "enable") {\
					self.setPinState("enable");\
				}\
				if(this.state == "change") {\
					this.result = self.doChangePin();\
					if (this.result == false) {\
					  $("input[name=\'pin\']").val(\'\');\
					  $("input[name=\'newpin\']").val(\'\');\
					  $("input[name=\'rnewpin\']").val(\'\');\
					  $("#pin-error-msg").removeClass("hide");\
					}\
				}\
				if(this.state == "unlock") {\
					self.unlockPin();\
				}\
				if(this.state == "unblock") {\
					self.unblockPin();\
				}\
			});\
			$("#reset-cancel").on("click", function() {\
				this.state = self.simViewState();\
				if(this.state == "disable") {\
					$("#grp-change-pin").removeClass("hide");\
				}\
				if(this.state == "change") {\
					$("#grp-disable-pin").removeClass("hide");\
				}\
				self.setSimView("default");\
			});\
		};\
\
		var simView = new simView();\
		ko.applyBindings(simView, document.getElementById(\'lte-sim-body\'));\
		simView.refresh();\
	});\
</script>\
'); 