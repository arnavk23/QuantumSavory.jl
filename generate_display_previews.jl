using QuantumSavory
using QuantumSavory.ProtocolZoo
using QuantumSavory.ProtocolZoo.QTCP
using Gabs
using Dates

# Helper to write HTML to file with CSS styling
function write_html_file(filename, title, html_body)
    open(filename, "w") do f
        write(f, """
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>$title</title>
<style>
body { font-family: system-ui, -apple-system, sans-serif; max-width: 960px; margin: 2em auto; padding: 0 1em; background: #f5f5f5; }
h1 { color: #333; }
h2 { color: #555; margin-top: 2em; }
.preview { background: white; border: 1px solid #ddd; border-radius: 8px; padding: 1em; margin: 1em 0; overflow-x: auto; }
.quantumsavory_show { font-family: system-ui, -apple-system, sans-serif; }
.quantumsavory_show table { border-collapse: collapse; }
.quantumsavory_show td, .quantumsavory_show th { padding: 0.3em 0.6em; border: 1px solid #ccc; }
pre { background: #f0f0f0; padding: 0.5em; border-radius: 4px; overflow-x: auto; }
</style></head><body>
<h1>$title</h1>
<div class="preview">
$html_body
</div>
</body></html>
""")
    end
end

mkpath("display_previews")

# Basic register with mixed backends
reg = Register([Qubit(), Qumode()], [CliffordRepr(), QuantumOpticsRepr()], [PauliNoise(0.1,0.1,0.1), AmplitudeDamping(0.2)])
initialize!(reg[1], X1)

# Register with names
reg_named = Register([Qubit(), Qumode()], [QuantumOpticsRepr(), QuantumOpticsRepr()], [PauliNoise(0.1,0.1,0.1), AmplitudeDamping(0.2)])
reg_named2 = Register([Qubit(), Qumode()], [QuantumOpticsRepr(), QuantumOpticsRepr()], [PauliNoise(0.1,0.1,0.1), AmplitudeDamping(0.2)])
net = RegisterNet([reg_named, reg_named2]; name="my net", names=["reg 1", "reg 2"])
initialize!((reg_named[1], reg_named2[1]), X1⊗Z1 + Z1⊗X1)

# --- RegRef html ---
regref_html = repr(MIME"text/html"(), reg[1])
regref_text = repr(reg[1])
write_html_file("display_previews/regref.html", "RegRef Display", regref_html)
open("display_previews/regref.txt", "w") do f; write(f, regref_text); end

# --- StateRef html (Clifford) ---
stateref_cliff_html = repr(MIME"text/html"(), QuantumSavory.stateof(reg[1]))
stateref_cliff_text = repr(QuantumSavory.stateof(reg[1]))
write_html_file("display_previews/stateref_clifford.html", "StateRef (Clifford Repr)", stateref_cliff_html)
open("display_previews/stateref_clifford.txt", "w") do f; write(f, stateref_cliff_text); end

# --- StateRef html (QuantumOptics, entangled) ---
stateref_qo_html = repr(MIME"text/html"(), QuantumSavory.stateof(reg_named[1]))
stateref_qo_text = repr(QuantumSavory.stateof(reg_named[1]))
write_html_file("display_previews/stateref_quantumoptics.html", "StateRef (QuantumOptics, entangled)", stateref_qo_html)
open("display_previews/stateref_quantumoptics.txt", "w") do f; write(f, stateref_qo_text); end

# --- Register text/plain ---
reg_text = repr(reg_named)
open("display_previews/register.txt", "w") do f; write(f, reg_text); end

# --- RegisterNet text/plain ---
net_text = repr(net)
open("display_previews/registernet.txt", "w") do f; write(f, net_text); end


# 2. Gaussian State

gaus_reg = Register([Qumode()], [GabsRepr(QuadPairBasis)])
initialize!(gaus_reg[1], CoherentState(0.2 - 0.5im))
apply!(gaus_reg[1], DisplaceOp(0.6 - 0.4im))

gaus_html = repr(MIME"text/html"(), QuantumSavory.stateof(gaus_reg[1]))
gaus_text = repr(QuantumSavory.stateof(gaus_reg[1]))
write_html_file("display_previews/gaussian_state.html", "Gaussian State Display", gaus_html)
open("display_previews/gaussian_state.txt", "w") do f; write(f, gaus_text); end


# 3. ProtocolZoo - EntanglerProt

reg1 = Register([Qubit(), Qubit()], [CliffordRepr(), CliffordRepr()])
reg2 = Register([Qubit(), Qubit()], [CliffordRepr(), CliffordRepr()])
net2 = RegisterNet([reg1, reg2]; name="entangler-net")

prot = EntanglerProt(get_time_tracker(net2), net2, 1, 2; success_prob=0.8)
prot_html = repr(MIME"text/html"(), prot)
prot_text = repr(prot)
write_html_file("display_previews/entangler_prot.html", "EntanglerProt Display", prot_html)
open("display_previews/entangler_prot.txt", "w") do f; write(f, prot_text); end


# 4. ProtocolZoo - EntanglementConsumer (empty)

consumer = EntanglementConsumer(get_time_tracker(net2), net2, 1, 2)
consumer_html = repr(MIME"text/html"(), consumer)
consumer_text = repr(consumer)
write_html_file("display_previews/entanglement_consumer_empty.html", "EntanglementConsumer (empty) Display", consumer_html)
open("display_previews/entanglement_consumer_empty.txt", "w") do f; write(f, consumer_text); end


# 5. QTCP Controllers

qnet = RegisterNet([Register(6), Register(6), Register(6)]; name="qtcp-display-net", names=["n1", "n2", "n3"])
qsim = get_time_tracker(qnet)

# Populate with some messages
put!(qnet[1], Flow(src=1, dst=3, npairs=2, uuid=11))
put!(qnet[1], QDatagram(flow_uuid=11, flow_src=1, flow_dst=3, correction=0, seq_num=1, start_time=0.0))
put!(qnet[1], QTCP.QDatagramSuccess(flow_uuid=11, seq_num=1, start_time=0.0))
put!(qnet[1], LinkLevelReplyAtSource(flow_uuid=11, seq_num=1, memory_slot=2))
put!(qnet[1], QTCPPairBegin(flow_uuid=11, flow_src=1, flow_dst=3, seq_num=1, memory_slot=2, start_time=0.0))

put!(qnet[2], QDatagram(flow_uuid=21, flow_src=1, flow_dst=3, correction=0, seq_num=4, start_time=1.0))
put!(qnet[2], LinkLevelReply(flow_uuid=21, seq_num=4, memory_slot=1))
put!(qnet[2], LinkLevelReplyAtHop(flow_uuid=21, seq_num=4, memory_slot=5))

put!(qnet[1], LinkLevelRequest(flow_uuid=33, seq_num=1, remote_node=2))
put!(qnet[1], LinkLevelReply(flow_uuid=33, seq_num=1, memory_slot=3))
put!(qnet[2], LinkLevelRequest(flow_uuid=33, seq_num=1, remote_node=1))
put!(qnet[2], LinkLevelReplyAtHop(flow_uuid=33, seq_num=1, memory_slot=4))

# --- EndNodeController ---
end_node = EndNodeController(qsim, qnet, 1)
end_html = repr(MIME"text/html"(), end_node)
end_text = repr(end_node)
write_html_file("display_previews/qtcp_endnode.html", "QTCP EndNodeController Display", end_html)
open("display_previews/qtcp_endnode.txt", "w") do f; write(f, end_text); end

# --- NetworkNodeController ---
network_node = NetworkNodeController(qsim, qnet, 2)
network_html = repr(MIME"text/html"(), network_node)
network_text = repr(network_node)
write_html_file("display_previews/qtcp_networknode.html", "QTCP NetworkNodeController Display", network_html)
open("display_previews/qtcp_networknode.txt", "w") do f; write(f, network_text); end

# --- LinkController ---
link = LinkController(qsim, qnet, 1, 2)
link_html = repr(MIME"text/html"(), link)
link_text = repr(link)
write_html_file("display_previews/qtcp_link.html", "QTCP LinkController Display", link_html)
open("display_previews/qtcp_link.txt", "w") do f; write(f, link_text); end


