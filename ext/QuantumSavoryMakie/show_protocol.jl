function Base.show(io::IO, m::MIME"image/png", prot::QuantumSavory.ProtocolZoo.AbstractProtocol)
    f = Figure()
    protshowimage(f, prot)
    show(io, m, f)
end

"""Similar to `show(io, ::MIME"", ...)`, but private to avoid piracy. Instead of an IO instance, it takes a Makie axis."""
function protshowimage(subfig, prot)
    a = Axis(subfig[1,1])
    hidedecorations!(a)
    hidespines!(a)
    text = "protocol of type\n$(typeof(prot))\ndoes not support rich visualization"
    text!(a,0,0;text,align=(:center,:center))
end

function protshowimage(subfig, prot::QuantumSavory.ProtocolZoo.EntanglerProt)
    l = Label(subfig[1,1], text="State generated between\n$(compactstr(prot.net[prot.nodeA])) and $(compactstr(prot.net[prot.nodeB]))", tellwidth=false)
    se = stateexplorer!(subfig[2,1], dm(express(prot.pairstate)))
    ldist = Label(subfig[3,1], text="Time to generate a state\n(Geometric distribution)", tellwidth=false)
    adist = Axis(subfig[4,1], xlabel="Attempt", ylabel="Success probability")
    p = prot.success_prob
    attempts = 1:Int(floor(3/p))
    Makie.stairs!(adist, attempts, (1-p).^(attempts.-1).*p; step=:center)
    Makie.vlines!(adist, [1/p], color=:gray)
    Makie.text!(adist, 1/p, 0.0, text=" Mean time:\n$(@sprintf " %.4g" (1/p))", color=:black)
end

function protshowimage(subfig, prot::QuantumSavory.ProtocolZoo.EntanglementConsumer)
    l = Label(subfig[1,1], text="Fidelity of consumed pairs between\n$(compactstr(prot.net[prot.nodeA])) and $(compactstr(prot.net[prot.nodeB]))", tellwidth=false)
    a = Axis(subfig[2,1], xlabel="Time", ylabel="Observable")
    t = [t for (t, _, _) in prot._log]
    zz = [z for (_, z, _) in prot._log]
    xx = [x for (_, _, x) in prot._log]
    scatter!(a, t, zz, label="ZZ")
    scatter!(a, t, xx, label="XX")
    hlines!(a, 0.0, color=:gray)
    hlines!(a, 1.0, color=:gray)
    axislegend(a, position=:lb)
    lh = Label(subfig[3,1], text="Histogram of time to consume a pair", tellwidth=false)
    ah = Axis(subfig[4,1], xlabel="ΔTime", ylabel="Fraction")
    Makie.hist!(ah, diff([0; t]), normalization=:probability)
    avg = sum(diff([0; t]))/length(t)
    Makie.vlines!(ah, avg, color=:gray)
    Makie.text!(ah, avg, 0.0, text=" Mean time:\n$(@sprintf " %.4g" avg)", color=:black)
end

function protshowimage(subfig, prot::QuantumSavory.ProtocolZoo.EndNodeController)
    mb = messagebuffer(prot.net, prot.node)
    counts = QuantumSavory.ProtocolZoo._qtcp_message_counts(mb)
    begin_pairs = QuantumSavory.ProtocolZoo._qtcp_pair_summaries(mb, QuantumSavory.ProtocolZoo.QTCPPairBegin)
    end_pairs = QuantumSavory.ProtocolZoo._qtcp_pair_summaries(mb, QuantumSavory.ProtocolZoo.QTCPPairEnd)
    pairs_str = if !isempty(begin_pairs) || !isempty(end_pairs)
        "pairs begin=[$(join(begin_pairs, ", "))] end=[$(join(end_pairs, ", "))]"
    else
        "no pairs"
    end
    Label(subfig[1,1], text=rich("EndNodeController @ node ", rich("$(prot.node)", font=:bold)), tellwidth=false)
    a = Axis(subfig[2,1])
    hidedecorations!(a)
    hidespines!(a)
    xlims!(a, 0, 1)
    ylims!(a, 0, 1)
    Makie.text!(a, 0, 1, text=rich(
        rich("time: ", color=:gray), "$(ConcurrentSim.now(prot.sim))",
        rich("\nregister: ", color=:gray), "$(compactstr(prot.net[prot.node]))",
        rich("\n\nFlow: ", font=:bold, color=:teal), "$(get(counts, QuantumSavory.ProtocolZoo.Flow, 0))",
        rich("\nQDatagram: ", font=:bold, color=:dodgerblue), "$(get(counts, QuantumSavory.ProtocolZoo.QDatagram, 0))",
        rich("\nQDatagramSuccess: ", font=:bold, color=:dodgerblue), "$(get(counts, QuantumSavory.ProtocolZoo.QTCP.QDatagramSuccess, 0))",
        rich("\nLinkLevelReplyAtSource: ", font=:bold, color=:purple), "$(get(counts, QuantumSavory.ProtocolZoo.LinkLevelReplyAtSource, 0))",
        rich("\nQTCPPairBegin: ", font=:bold, color=:green), "$(get(counts, QuantumSavory.ProtocolZoo.QTCPPairBegin, 0))",
        rich("\nQTCPPairEnd: ", font=:bold, color=:orange), "$(get(counts, QuantumSavory.ProtocolZoo.QTCPPairEnd, 0))",
        rich("\n\n", color=:gray), "$pairs_str",
    ), align=(:left, :top))
end

function protshowimage(subfig, prot::QuantumSavory.ProtocolZoo.NetworkNodeController)
    mb = messagebuffer(prot.net, prot.node)
    counts = QuantumSavory.ProtocolZoo._qtcp_message_counts(mb)
    datagrams = QuantumSavory.ProtocolZoo._qtcp_visible_qdatagrams(mb)
    incoming = count(d -> d.flow_src != prot.node, datagrams)
    outgoing = count(d -> d.flow_src == prot.node, datagrams)
    next_hops = QuantumSavory.ProtocolZoo._qtcp_inferred_next_hops(prot.net.graph, prot.node, datagrams)
    hops_str = isempty(next_hops) ? "none" : join(("$(flow_uuid).$(seq_num)->$(hop)" for ((flow_uuid, seq_num, _), hop) in sort(collect(next_hops); by=first)), ", ")
    neighbors = collect(Graphs.neighbors(prot.net.graph, prot.node))
    Label(subfig[1,1], text=rich("NetworkNodeController @ node ", rich("$(prot.node)", font=:bold)), tellwidth=false)
    a = Axis(subfig[2,1])
    hidedecorations!(a)
    hidespines!(a)
    xlims!(a, 0, 1)
    ylims!(a, 0, 1)
    Makie.text!(a, 0, 1, text=rich(
        rich("neighbors: ", color=:gray), "$(join(sort(neighbors), ", "))",
        rich("\ndegree: ", color=:gray), "$(Graphs.degree(prot.net.graph, prot.node))",
        rich("\n\nQDatagram ", font=:bold, color=:dodgerblue),
        rich("in/out: "), "$(incoming)/$(outgoing)",
        rich("\nLinkLevelReply: ", font=:bold, color=:purple), "$(get(counts, QuantumSavory.ProtocolZoo.LinkLevelReply, 0))",
        rich("\nLinkLevelReplyAtHop: ", font=:bold, color=:purple), "$(get(counts, QuantumSavory.ProtocolZoo.LinkLevelReplyAtHop, 0))",
        rich("\n\nnext hops: ", color=:gray), "$hops_str",
    ), align=(:left, :top))
end

function protshowimage(subfig, prot::QuantumSavory.ProtocolZoo.LinkController)
    mb_a = messagebuffer(prot.net, prot.nodeA)
    mb_b = messagebuffer(prot.net, prot.nodeB)
    counts_a = QuantumSavory.ProtocolZoo._qtcp_message_counts(mb_a)
    counts_b = QuantumSavory.ProtocolZoo._qtcp_message_counts(mb_b)
    Label(subfig[1,1], text=rich(
        "LinkController ",
        rich("$(prot.nodeA)", color=:dodgerblue), rich(" <-> ", color=:gray), rich("$(prot.nodeB)", color=:orange),
    ), tellwidth=false)
    a = Axis(subfig[2,1])
    hidedecorations!(a)
    hidespines!(a)
    xlims!(a, 0, 1)
    ylims!(a, 0, 1)
    Makie.text!(a, 0, 1, text=rich(
        rich("time: ", color=:gray), "$(ConcurrentSim.now(prot.sim))",
        rich("\n\n", font=:bold, color=:dodgerblue), "Node $(prot.nodeA)",
        rich("\n  register: ", color=:gray), "$(compactstr(prot.net[prot.nodeA]))",
        rich("\n  slots: ", color=:gray), "$(nsubsystems(prot.net[prot.nodeA]))",
        rich("\n  req: ", color=:gray), "$(get(counts_a, QuantumSavory.ProtocolZoo.LinkLevelRequest, 0))",
        rich("  reply: ", color=:gray), "$(get(counts_a, QuantumSavory.ProtocolZoo.LinkLevelReply, 0))",
        rich("  at_hop: ", color=:gray), "$(get(counts_a, QuantumSavory.ProtocolZoo.LinkLevelReplyAtHop, 0))",
        rich("\n\n", font=:bold, color=:orange), "Node $(prot.nodeB)",
        rich("\n  register: ", color=:gray), "$(compactstr(prot.net[prot.nodeB]))",
        rich("\n  slots: ", color=:gray), "$(nsubsystems(prot.net[prot.nodeB]))",
        rich("\n  req: ", color=:gray), "$(get(counts_b, QuantumSavory.ProtocolZoo.LinkLevelRequest, 0))",
        rich("  reply: ", color=:gray), "$(get(counts_b, QuantumSavory.ProtocolZoo.LinkLevelReply, 0))",
        rich("  at_hop: ", color=:gray), "$(get(counts_b, QuantumSavory.ProtocolZoo.LinkLevelReplyAtHop, 0))",
    ), align=(:left, :top))
end
