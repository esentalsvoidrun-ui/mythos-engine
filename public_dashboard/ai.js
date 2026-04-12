
async function loadAI() {
  const el = document.getElementById("ai-box");

  el.innerHTML = "⏳ Thinking like a VC...";

  try {
    const res = await fetch("/api/insights");
    const data = await res.json();

    let text = data.insights || "No insights";

    // snygg radbrytning + lite stil
    text = text
      .replace(/\\n/g, "<br>")
      .replace(/Users/g, "👥 Users")
      .replace(/Revenue/g, "💰 Revenue")
      .replace(/Sessions/g, "📊 Sessions");

    el.innerHTML = text;

  } catch (err) {
    el.innerHTML = "⚠️ AI offline";
  }
}

// kör direkt + uppdatera var 5:e sekund
loadAI();
setInterval(loadAI, 5000);

