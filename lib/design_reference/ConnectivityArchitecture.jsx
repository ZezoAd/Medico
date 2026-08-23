import { useState, useEffect, useRef } from "react";
import { Stethoscope, MapPin, Clock, RotateCw, WifiOff } from "lucide-react";

const AR = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];
const ar = (n) => String(n).split("").map((d) => AR[+d]).join("");

const AURORA = { from: "#2A93C9", to: "#1D9E75" };
const AHEAD = 5;
const PER_PATIENT_MIN = 5;
const RETRY_SECONDS = 10;

const clock = (d) => {
  let h = d.getHours();
  const m = d.getMinutes();
  const period = h >= 12 ? "م" : "ص";
  h = h % 12 || 12;
  return `${ar(h)}:${ar(String(m).padStart(2, "0"))} ${period}`;
};

function RetryRing({ pct }) {
  const r = 8, c = 2 * Math.PI * r;
  return (
    <svg width="18" height="18" viewBox="0 0 20 20" className="shrink-0">
      <circle cx="10" cy="10" r={r} fill="none" stroke="rgba(255,255,255,0.28)" strokeWidth="2.5" />
      <circle cx="10" cy="10" r={r} fill="none" stroke="#fff" strokeWidth="2.5"
        strokeDasharray={c} strokeDashoffset={c * (1 - pct)} strokeLinecap="round"
        transform="rotate(-90 10 10)" style={{ transition: "stroke-dashoffset 1s linear" }} />
    </svg>
  );
}

/* the fact, stated once, no animation — there's nothing to visibly "retry" */
function GlobalOfflineStrip({ show }) {
  return (
    <div
      className="overflow-hidden transition-all duration-400"
      style={{ maxHeight: show ? 44 : 0, opacity: show ? 1 : 0 }}
    >
      <div
        className="flex items-center gap-2 rounded-xl px-3 py-2.5 text-xs font-bold"
        style={{ background: "#2B3733", color: "#EAF0EC" }}
      >
        <WifiOff className="h-3.5 w-3.5 shrink-0" />
        لا يوجد اتصال بالإنترنت حالياً
      </div>
    </div>
  );
}

function Badge({ mode, secondsLeft }) {
  if (mode === "live") {
    return (
      <span className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-bold"
        style={{ background: "rgba(255,255,255,0.18)", border: "1px solid rgba(255,255,255,0.28)" }}>
        <span className="relative flex h-2 w-2">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-white opacity-75" />
          <span className="relative inline-flex h-2 w-2 rounded-full bg-white" />
        </span>
        مباشر
      </span>
    );
  }
  if (mode === "retrying") {
    return (
      <span className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-bold"
        style={{ background: "rgba(255,255,255,0.16)", border: "1px solid rgba(255,255,255,0.26)" }}>
        <RetryRing pct={secondsLeft / RETRY_SECONDS} />
        يعيد الاتصال
      </span>
    );
  }
  // stale — points at the DATA, not at the visit itself
  return (
    <span className="inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-bold"
      style={{ background: "rgba(255,255,255,0.14)", border: "1px solid rgba(255,255,255,0.22)" }}>
      <Clock className="h-3 w-3" />
      آخر تحديث
    </span>
  );
}

export default function ConnectivityArchitecture() {
  // scenario: "live" | "channelDrop" (internet fine, realtime channel drops) | "noInternet" (device offline)
  const [scenario, setScenario] = useState("live");
  const [secondsLeft, setSecondsLeft] = useState(RETRY_SECONDS);
  const frozenRef = useRef(null);

  const cardMode =
    scenario === "live" ? "live"
    : scenario === "noInternet" ? "stale"      // skip retry entirely — nothing to retry
    : secondsLeft > 0 ? "retrying" : "stale";  // channel drop: retry first, then stale

  useEffect(() => {
    if (scenario !== "channelDrop") { setSecondsLeft(RETRY_SECONDS); return; }
    const id = setInterval(() => setSecondsLeft((s) => Math.max(0, s - 1)), 1000);
    return () => clearInterval(id);
  }, [scenario]);

  useEffect(() => {
    if (cardMode === "live") frozenRef.current = null;
    else if (cardMode === "stale" && !frozenRef.current) frozenRef.current = new Date();
  }, [cardMode]);

  const recordedAt = frozenRef.current ?? new Date();
  const estimateAt = new Date(recordedAt.getTime() + AHEAD * PER_PATIENT_MIN * 60000);
  const frozen = cardMode === "stale";

  return (
    <div dir="rtl" className="min-h-screen p-4"
      style={{ fontFamily: "Tajawal, system-ui, sans-serif", background: "linear-gradient(180deg,#F5F4EF,#EFF3F0)" }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&display=swap');
        .blob-layer { position:absolute; inset:0; overflow:hidden; pointer-events:none; transition: filter 600ms ease, opacity 600ms ease; }
        .blob { position:absolute; border-radius:50%; background:rgba(255,255,255,0.11); }
        .b1 { width:190px; height:190px; top:-95px; right:-55px; animation: drift1 26s ease-in-out infinite; }
        .b2 { width:130px; height:130px; bottom:-70px; left:-35px; background:rgba(255,255,255,0.07); animation: drift2 34s ease-in-out infinite; }
        .b3 { width:90px; height:90px; top:40%; left:-20px; background:rgba(255,255,255,0.05); animation: drift3 21s ease-in-out infinite; }
        .paused-blobs { animation-play-state: paused !important; filter: blur(6px); opacity: 0.7; }
        @keyframes drift1 { 0%{transform:translate(0,0) scale(1);} 30%{transform:translate(-14px,10px) scale(1.05);} 58%{transform:translate(6px,18px) scale(0.97);} 80%{transform:translate(-8px,-6px) scale(1.03);} 100%{transform:translate(0,0) scale(1);} }
        @keyframes drift2 { 0%{transform:translate(0,0) scale(1);} 25%{transform:translate(12px,-14px) scale(1.06);} 52%{transform:translate(18px,4px) scale(0.96);} 77%{transform:translate(-6px,12px) scale(1.02);} 100%{transform:translate(0,0) scale(1);} }
        @keyframes drift3 { 0%{transform:translate(0,0) scale(1);} 35%{transform:translate(10px,-8px) scale(1.08);} 65%{transform:translate(-4px,10px) scale(0.94);} 100%{transform:translate(0,0) scale(1);} }
        @media (prefers-reduced-motion: reduce) { .blob { animation: none !important; } }
      `}</style>

      <div className="mx-auto flex max-w-sm flex-col gap-4">
        <div className="grid grid-cols-3 gap-2">
          {[
            ["live", "متصل"],
            ["channelDrop", "انقطاع القناة فقط"],
            ["noInternet", "لا إنترنت كلياً"],
          ].map(([key, label]) => (
            <button key={key} onClick={() => setScenario(key)}
              className="rounded-lg py-2 text-[11px] font-bold transition-colors"
              style={{
                background: scenario === key ? "#0F6E56" : "#fff",
                color: scenario === key ? "#fff" : "#6F7D78",
                border: "1px solid #E7E9E2",
              }}>
              {label}
            </button>
          ))}
        </div>

        {/* global layer — appears ONLY for true device offline, above everything */}
        <GlobalOfflineStrip show={scenario === "noInternet"} />

        {scenario === "channelDrop" && cardMode === "retrying" && (
          <p className="text-center text-xs font-semibold" style={{ color: "#6F7D78" }}>
            الجهاز متصل بالإنترنت — نحاول استعادة تتبّع الدور المباشر ({ar(secondsLeft)})
          </p>
        )}

        {/* the card — unaware of WHY it's stale, only THAT it is */}
        <div className="relative overflow-hidden rounded-2xl p-5 text-white transition-all duration-500"
          style={{
            background: `linear-gradient(140deg,${AURORA.from} 0%,${AURORA.to} 100%)`,
            boxShadow: "0 18px 36px -20px rgba(6,45,36,0.55)",
          }}>

          <div className={`blob-layer ${frozen ? "paused-blobs" : ""}`}>
            <span className="blob b1" /><span className="blob b2" /><span className="blob b3" />
          </div>
          <div className="pointer-events-none absolute inset-0 transition-opacity duration-500"
            style={{ background: "rgba(10,20,17,0.30)", opacity: frozen ? 1 : 0, backdropFilter: frozen ? "blur(1.5px)" : "none" }} />

          <div className="relative flex items-center gap-3">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl" style={{ background: "rgba(255,255,255,0.20)", border: "1px solid rgba(255,255,255,0.35)" }}>
              <Stethoscope className="h-5 w-5" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-extrabold">د. محمد طاهر</p>
              <p className="mt-0.5 flex items-center gap-1 text-xs font-medium" style={{ color: "rgba(255,255,255,0.85)" }}>
                <MapPin className="h-3 w-3" />عيادة النخيل · الطابق الثاني
              </p>
            </div>
            <Badge mode={cardMode} secondsLeft={secondsLeft} />
          </div>

          <div className="relative mt-6 flex items-baseline gap-3">
            <span className="text-6xl font-extrabold leading-none tabular-nums tracking-tight">{ar(AHEAD)}</span>
            <span className="text-base font-extrabold" style={{ color: "rgba(255,255,255,0.92)" }}>مرضى قبلك</span>
          </div>

          {!frozen ? (
            <p className="relative mt-3 text-sm font-extrabold">دورك خلال ٢٠–٣٠ دقيقة تقريباً</p>
          ) : (
            <div className="relative mt-3">
              <p className="text-xs font-semibold" style={{ color: "rgba(255,255,255,0.75)" }}>
                سُجّلت هذه الأرقام الساعة {clock(recordedAt)}
              </p>
              <p className="mt-1.5 text-base font-extrabold">دورك المتوقع نحو الساعة {clock(estimateAt)}</p>
            </div>
          )}

          <div className="relative mt-5 h-2 w-full overflow-hidden rounded-full" style={{ background: "rgba(255,255,255,0.24)" }}>
            <div className="h-full w-7/12 rounded-full bg-white transition-all duration-500" />
          </div>
          <div className="relative mt-2 flex justify-between text-xs font-semibold" style={{ color: "rgba(255,255,255,0.8)" }}>
            <span>الطبيب الآن</span><span>دورك</span>
          </div>

          {frozen && scenario === "channelDrop" && (
            <button className="relative mt-4 flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-xs font-bold transition-transform active:scale-97"
              style={{ background: "rgba(255,255,255,0.16)", border: "1px solid rgba(255,255,255,0.26)" }}
              onClick={() => setScenario("live")}>
              <RotateCw className="h-3.5 w-3.5" />إعادة المحاولة الآن
            </button>
          )}
        </div>

        <p className="px-1 text-center text-xs font-medium" style={{ color: "#6F7D78" }}>
          الشريط العلوي يصف حالة الجهاز — البطاقة تعرض حالة تتبّع هذا الدور تحديداً
        </p>
      </div>
    </div>
  );
}
