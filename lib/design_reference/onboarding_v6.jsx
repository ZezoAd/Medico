import React, { useState, useRef, useEffect } from "react";
import {
  ArrowRight,
  ChevronDown,
  MapPin,
  Check,
  Bell,
  BellRing,
  Timer,
  BadgeCheck,
  PauseCircle,
} from "lucide-react";

/* =====================================================================
   DESIGN TOKENS — every value below references this scale, no one-offs
===================================================================== */
const AURORA = "linear-gradient(135deg, #2A93C9 0%, #1D9E75 100%)";

const C = {
  primary: "#1D9E75",
  primaryBlue: "#2A93C9",
  ink: "#122B28",
  secondary: "#5C7A74",
  muted: "#8FA5A0",
  background: "#F5F9F8",
  surface: "#FFFFFF",
  tonal: "#E6F1EE",
  divider: "#DEEAE7",
  disabledInk: "#9DB0AB",
};

/* spacing scale (4pt base) */
const S = { xs: 4, sm: 8, md: 12, lg: 16, xl: 20, xxl: 24, xxxl: 32 };
/* radius scale */
const R = { sm: 12, md: 16, lg: 20, xl: 28, pill: 999 };
/* type scale — 1.25 ratio */
const F = { micro: 11, caption: 12.5, body: 14, bodyLg: 15, h3: 17, h2: 20, h1: 26, display: 34 };
/* motion */
const M = {
  press: "transform 140ms cubic-bezier(0.33,1,0.68,1)",
  standard: "300ms cubic-bezier(0.33,1,0.68,1)",
  page: "520ms cubic-bezier(0.33,1,0.68,1)",
  spring: "cubic-bezier(0.34,1.56,0.64,1)",
};
/* elevation — max two shadowed layers per view */
const E = {
  card: "0 8px 24px rgba(18,43,40,0.06)",
  lift: "0 10px 26px rgba(29,158,117,0.28)",
  sheet: "0 -8px 40px rgba(18,43,40,0.14)",
};

const displayFont = { fontFamily: "'Noto Kufi Arabic', sans-serif" };
const bodyFont = { fontFamily: "'Tajawal', sans-serif" };

const GOVERNORATES = [
  "بغداد", "البصرة", "نينوى", "أربيل", "السليمانية", "دهوك",
  "كركوك", "الأنبار", "ديالى", "صلاح الدين", "بابل", "كربلاء",
  "النجف", "واسط", "القادسية", "ميسان", "ذي قار", "المثنى",
];

const CURRENT_YEAR = new Date().getFullYear();
// NOTE: the wheel intentionally runs up to the current year so it opens on it.
// Minimum-age validation is a BACKEND concern — see note to Zezo.
const YEARS = Array.from({ length: CURRENT_YEAR - 1935 + 1 }, (_, i) => 1935 + i);
const STEP_LABELS = ["معلومات أساسية", "مدينتك", "الإشعارات"];

/* =====================================================================
   FIX 3 — Milestone path: label sits UNDER its own icon, not centered
   Rendered row-reverse so step 1 is rightmost (RTL reading order)
===================================================================== */
function PersonGlyph({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="8" r="4" stroke="currentColor" strokeWidth="2" />
      <path d="M4 20c0-4 3.5-7 8-7s8 3 8 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

function MilestonePath({ step }) {
  const COL = 76;            // column width; circle is centered inside it
  const HALF = COL / 2;      // distance from container edge to first circle centre
  const CIRCLE_TOP = 18.5;   // vertical centre of the 40px circle

  return (
    <div style={{ width: "100%", position: "relative" }}>
      {/* one continuous track running behind every node, edge to edge */}
      <div
        style={{
          position: "absolute",
          top: CIRCLE_TOP,
          left: HALF,
          right: HALF,
          height: 3,
          borderRadius: R.pill,
          background: C.divider,
          zIndex: 0,
        }}
      />
      {/* the fill grows along that same track as steps complete */}
      <div
        style={{
          position: "absolute",
          top: CIRCLE_TOP,
          right: HALF,
          width: `calc((100% - ${COL}px) * ${step / 2})`,
          height: 3,
          borderRadius: R.pill,
          background: AURORA,
          zIndex: 0,
          transition: "width 520ms cubic-bezier(0.33,1,0.68,1)",
        }}
      />

      <div
        style={{
          display: "flex",
          flexDirection: "row-reverse",
          justifyContent: "space-between",
          position: "relative",
          zIndex: 1,
        }}
      >
        {[0, 1, 2].map((i) => {
          const isDone = step > i;
          const isActive = step === i;
          const filled = isDone || isActive;
          return (
            <div key={i} style={{ display: "flex", flexDirection: "column", alignItems: "center", width: COL, flexShrink: 0 }}>
              <div
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: R.pill,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: filled ? "#fff" : C.muted,
                  background: filled ? AURORA : C.tonal,
                  // solid ring in the page colour so the track reads as passing
                  // behind the node rather than colliding with it
                  boxShadow: isActive
                    ? `0 0 0 4px ${C.background}, 0 0 0 8px rgba(29,158,117,0.16)`
                    : `0 0 0 4px ${C.background}`,
                  transform: isActive ? "scale(1)" : "scale(0.86)",
                  transition: `background ${M.standard}, color ${M.standard}, transform ${M.standard}, box-shadow ${M.standard}`,
                }}
              >
                {isDone ? <Check size={17} strokeWidth={3} /> : i === 0 ? <PersonGlyph /> : i === 1 ? <MapPin size={16} /> : <Bell size={16} />}
              </div>
              <div
                style={{
                  ...bodyFont,
                  fontSize: F.micro,
                  fontWeight: 700,
                  marginTop: S.sm,
                  textAlign: "center",
                  lineHeight: 1.3,
                  color: isActive ? C.primary : isDone ? C.secondary : C.muted,
                  transition: `color ${M.standard}`,
                }}
              >
                {STEP_LABELS[i]}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function StepHeader({ onBack, step, visible }) {
  return (
    <div
      style={{
        height: visible ? 132 : 0,
        opacity: visible ? 1 : 0,
        overflow: "hidden",
        padding: visible ? `${S.lg}px ${S.xl}px 0` : `0 ${S.xl}px`,
        // matches the page-slide timing so the bar and the pages move as one
        transition: "height 520ms cubic-bezier(0.33,1,0.68,1), opacity 320ms ease, padding 520ms cubic-bezier(0.33,1,0.68,1)",
      }}
    >
      <div style={{ display: "flex", flexDirection: "row-reverse", alignItems: "center", height: 40 }}>
        {onBack ? (
          <PressableIcon onClick={onBack} label="رجوع">
            <ArrowRight size={20} />
          </PressableIcon>
        ) : (
          <div style={{ width: 40, height: 40 }} />
        )}
      </div>
      <div style={{ padding: `${S.md}px ${S.xs}px 0` }}>
        <MilestonePath step={step} />
      </div>
    </div>
  );
}

/* =====================================================================
   Buttons — press feedback on every interactive (Doherty, ~140ms)
===================================================================== */
function usePress() {
  const [p, setP] = useState(false);
  return {
    pressed: p,
    bind: {
      onMouseDown: () => setP(true),
      onMouseUp: () => setP(false),
      onMouseLeave: () => setP(false),
      onTouchStart: () => setP(true),
      onTouchEnd: () => setP(false),
    },
  };
}

function PressableIcon({ children, onClick, label }) {
  const { pressed, bind } = usePress();
  return (
    <button
      onClick={onClick}
      aria-label={label}
      {...bind}
      style={{
        width: 40, height: 40, borderRadius: R.pill, background: C.tonal, border: "none",
        display: "flex", alignItems: "center", justifyContent: "center",
        cursor: "pointer", color: C.ink,
        transform: pressed ? "scale(0.92)" : "scale(1)",
        transition: M.press,
      }}
    >
      {children}
    </button>
  );
}

function PrimaryButton({ label, onClick, disabled, icon, flex }) {
  const { pressed, bind } = usePress();
  return (
    <button
      onClick={disabled ? undefined : onClick}
      disabled={disabled}
      {...(disabled ? {} : bind)}
      style={{
        flex: flex ? 1 : undefined,
        width: flex ? undefined : "100%",
        height: 56,
        borderRadius: R.md,
        border: "none",
        cursor: disabled ? "not-allowed" : "pointer",
        background: disabled ? C.divider : AURORA,
        color: disabled ? C.disabledInk : "#fff",
        ...bodyFont,
        fontSize: F.bodyLg,
        fontWeight: 700,
        display: "flex",
        flexDirection: "row-reverse",
        alignItems: "center",
        justifyContent: "center",
        gap: S.sm,
        boxShadow: disabled ? "none" : E.lift,
        transform: pressed ? "scale(0.97)" : "scale(1)",
        transition: `${M.press}, background 200ms, box-shadow 200ms`,
      }}
    >
      {icon}
      {label}
    </button>
  );
}

/* FIX 2 — compact skip that sits beside Continue, not in the header */
function InlineSkipButton({ label, onClick }) {
  const { pressed, bind } = usePress();
  return (
    <button
      onClick={onClick}
      {...bind}
      style={{
        width: 96, height: 56, borderRadius: R.md,
        border: `1.5px solid ${C.divider}`, background: "transparent",
        color: C.secondary, ...bodyFont, fontSize: F.body, fontWeight: 700,
        cursor: "pointer", flexShrink: 0,
        transform: pressed ? "scale(0.97)" : "scale(1)",
        transition: M.press,
      }}
    >
      {label}
    </button>
  );
}

function SecondaryButton({ label, onClick }) {
  const { pressed, bind } = usePress();
  return (
    <button
      onClick={onClick}
      {...bind}
      style={{
        width: "100%", height: 52, border: "none", background: "none", cursor: "pointer",
        ...bodyFont, fontSize: F.body, fontWeight: 700, color: C.secondary,
        transform: pressed ? "scale(0.97)" : "scale(1)",
        transition: M.press,
      }}
    >
      {label}
    </button>
  );
}

/* Section heading — one consistent treatment across all screens */
function SectionTitle({ children, hint }) {
  return (
    <>
      <h2 style={{ ...displayFont, fontSize: F.h3, fontWeight: 700, color: C.ink, margin: 0, textAlign: "right" }}>
        {children}
      </h2>
      {hint && (
        <p style={{ ...bodyFont, fontSize: F.caption, color: C.muted, lineHeight: 1.55, margin: `${S.xs}px 0 0`, textAlign: "right" }}>
          {hint}
        </p>
      )}
    </>
  );
}

/* =====================================================================
   FIX 2 — Gender: segmented control, RTL order (أنثى first = rightmost)
===================================================================== */
function GenderSegmented({ value, onChange }) {
  const idx = value === "أنثى" ? 0 : 1;
  // The indicator should APPEAR in place on the first pick, and only slide
  // on subsequent switches. So sliding stays off until one frame after
  // the first selection has painted.
  const [canSlide, setCanSlide] = useState(false);
  useEffect(() => {
    if (!value) {
      setCanSlide(false);
      return;
    }
    if (!canSlide) {
      const id = requestAnimationFrame(() => setCanSlide(true));
      return () => cancelAnimationFrame(id);
    }
  }, [value, canSlide]);

  return (
    <div
      style={{
        position: "relative",
        display: "flex",
        flexDirection: "row-reverse",
        background: C.tonal,
        borderRadius: R.lg,
        padding: 6,
        boxShadow: "inset 0 1px 3px rgba(18,43,40,0.07)",
      }}
    >
      <div
        style={{
          position: "absolute",
          top: 6,
          bottom: 6,
          width: "calc(50% - 6px)",
          right: idx === 0 ? 6 : "50%",
          background: value ? AURORA : "transparent",
          borderRadius: R.md,
          boxShadow: value ? E.lift : "none",
          opacity: value ? 1 : 0,
          transition: canSlide
            ? "right 420ms cubic-bezier(0.32,0.72,0,1), opacity 200ms"
            : "opacity 160ms ease-out",
        }}
      />
      {/* divider between the two options — fades once a selection sits flush
          against it so the two edges don't read as a doubled seam */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          right: "50%",
          transform: "translateY(-50%)",
          width: 2,
          height: 28,
          borderRadius: 1,
          // must contrast against the tonal track (#E6F1EE) — the old
          // divider token was nearly the same colour (1.07:1) and vanished.
          // C.secondary at full opacity measures 4.05:1.
          background: C.secondary,
          opacity: value ? 0 : 1,
          zIndex: 0,
          pointerEvents: "none",
          transition: "opacity 200ms ease",
        }}
      />
      {["أنثى", "ذكر"].map((g) => {
        const active = value === g;
        return (
          <button
            key={g}
            onClick={() => onChange(g)}
            style={{
              position: "relative", zIndex: 1, flex: 1, height: 52,
              background: "none", border: "none", cursor: "pointer",
              ...bodyFont, fontSize: F.bodyLg, fontWeight: 700,
              color: active ? "#fff" : C.secondary,
              transition: `color ${M.standard}`,
            }}
          >
            {g}
          </button>
        );
      })}
    </div>
  );
}

/* =====================================================================
   STEP 1 — Basics
===================================================================== */
function Step1({ data, setData, onContinue, onSkip, openYearSheet }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <div style={{ flex: 1, overflowY: "auto", padding: `${S.xxl}px ${S.xxl}px 0` }}>
        <h1 style={{ ...displayFont, fontSize: F.h1, fontWeight: 700, color: C.ink, margin: 0, textAlign: "right", lineHeight: 1.3 }}>
          لنتعرف عليك قليلاً
        </h1>
        {/* FIX 2 — no icon, more professional copy */}
        <p style={{ ...bodyFont, fontSize: F.body, color: C.secondary, lineHeight: 1.6, margin: `${S.md}px 0 0`, textAlign: "right" }}>
          معلومات اختيارية تساعدنا على عرض أطباء أنسب لك. يمكنك تعديلها في أي وقت من الإعدادات.
        </p>

        <div style={{ height: S.xxxl }} />
        <SectionTitle>الجنس</SectionTitle>
        <div style={{ height: S.lg }} />
        <GenderSegmented
          value={data.gender}
          onChange={(g) => setData({ ...data, gender: data.gender === g ? null : g })}
        />

        <div style={{ height: S.xxxl }} />
        <SectionTitle>سنة الميلاد</SectionTitle>
        <div style={{ height: S.lg }} />
        <YearField value={data.birthYear} onClick={openYearSheet} />
        <div style={{ height: S.xxl }} />
      </div>

      {/* FIX 2 — skip sits beside continue */}
      <div style={{ padding: `${S.lg}px ${S.xxl}px ${S.xxl}px`, display: "flex", flexDirection: "row-reverse", gap: S.md }}>
        <PrimaryButton label="متابعة" onClick={onContinue} flex />
        <InlineSkipButton label="تخطي" onClick={onSkip} />
      </div>
    </div>
  );
}

function YearField({ value, onClick }) {
  const { pressed, bind } = usePress();
  return (
    <button
      onClick={onClick}
      {...bind}
      style={{
        width: "100%", height: 56, borderRadius: R.md, border: "none",
        background: C.tonal, display: "flex", flexDirection: "row-reverse",
        alignItems: "center", padding: `0 ${S.lg}px`, cursor: "pointer", gap: S.md,
        transform: pressed ? "scale(0.985)" : "scale(1)",
        transition: M.press,
      }}
    >
      <span
        style={{
          ...bodyFont, fontSize: F.bodyLg,
          fontWeight: value ? 700 : 400,
          color: value ? C.ink : C.muted,
        }}
      >
        {value || "اختر سنة الميلاد"}
      </span>
      <div style={{ flex: 1 }} />
      <ChevronDown size={18} color={C.secondary} />
    </button>
  );
}

/* =====================================================================
   STEP 2 — City (FIX 2: no location icon beside the copy)
===================================================================== */
function Step2({ data, onContinue, openCitySheet }) {
  const selected = data.governorate;
  const { pressed, bind } = usePress();
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <div style={{ flex: 1, overflowY: "auto", padding: `${S.xxl}px ${S.xxl}px 0` }}>
        <h1 style={{ ...displayFont, fontSize: F.h1, fontWeight: 700, color: C.ink, margin: 0, textAlign: "right", lineHeight: 1.3 }}>
          أين تقيم؟
        </h1>
        <p style={{ ...bodyFont, fontSize: F.body, color: C.secondary, lineHeight: 1.6, margin: `${S.md}px 0 0`, textAlign: "right" }}>
          نستخدم هذه المعلومة لعرض الأطباء والعيادات الأقرب إليك.
        </p>

        <div style={{ height: S.xxxl }} />
        <SectionTitle>المحافظة</SectionTitle>
        <div style={{ height: S.lg }} />
        <button
          onClick={openCitySheet}
          {...bind}
          style={{
            width: "100%", padding: S.xl, borderRadius: R.lg,
            border: `1.5px solid ${selected ? "rgba(29,158,117,0.35)" : C.divider}`,
            background: C.surface, boxShadow: E.card,
            display: "flex", flexDirection: "row-reverse", alignItems: "center", gap: S.lg,
            cursor: "pointer",
            transform: pressed ? "scale(0.985)" : "scale(1)",
            transition: `${M.press}, border-color 200ms`,
          }}
        >
          <div
            style={{
              width: 44, height: 44, borderRadius: R.pill, background: C.tonal,
              display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
            }}
          >
            <MapPin size={20} color={C.primary} />
          </div>
          <div style={{ flex: 1, textAlign: "right", minWidth: 0 }}>
            <div
              style={{
                ...(selected ? displayFont : bodyFont),
                fontSize: selected ? F.h3 : F.bodyLg,
                fontWeight: selected ? 700 : 400,
                color: selected ? C.ink : C.muted,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}
            >
              {selected || "اختر محافظتك"}
            </div>
            {selected && (
              <div style={{ ...bodyFont, fontSize: F.caption, fontWeight: 600, color: C.muted, marginTop: 2 }}>
                اضغط للتغيير
              </div>
            )}
          </div>
          <ChevronDown size={20} color={C.secondary} />
        </button>
      </div>
      <div style={{ padding: `${S.lg}px ${S.xxl}px ${S.xxl}px` }}>
        <PrimaryButton label="متابعة" onClick={onContinue} disabled={!selected} />
      </div>
    </div>
  );
}

/* =====================================================================
   STEP 3 — Notifications (FIX 4: static, centered icon, better icons)
===================================================================== */
function BenefitRow({ icon, title, subtitle, last }) {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "row-reverse",
        gap: S.lg,
        alignItems: "center",
        padding: `${S.md}px 0`,
        borderBottom: last ? "none" : `1px solid ${C.divider}`,
      }}
    >
      <div
        style={{
          width: 46, height: 46, borderRadius: R.sm, background: C.tonal,
          display: "flex", alignItems: "center", justifyContent: "center",
          flexShrink: 0, color: C.primary,
        }}
      >
        {icon}
      </div>
      <div style={{ flex: 1, textAlign: "right", minWidth: 0 }}>
        <div style={{ ...bodyFont, fontSize: F.body, fontWeight: 700, color: C.ink }}>{title}</div>
        <div style={{ ...bodyFont, fontSize: F.caption, color: C.secondary, marginTop: 3, lineHeight: 1.5 }}>
          {subtitle}
        </div>
      </div>
    </div>
  );
}

function Step3({ onEnable, onMaybeLater }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      {/* no overflow scroll — content is sized to fit */}
      <div style={{ flex: 1, padding: `${S.xl}px ${S.xxl}px 0`, display: "flex", flexDirection: "column" }}>
        {/* FIX 4 — bell centered */}
        <div
          style={{
            width: 72, height: 72, borderRadius: R.pill, background: C.tonal,
            border: `1.5px solid rgba(29,158,117,0.28)`,
            display: "flex", alignItems: "center", justifyContent: "center",
            margin: "0 auto",
          }}
        >
          <Bell size={30} color={C.primary} />
        </div>
        <div style={{ height: S.lg }} />
        <h1 style={{ ...displayFont, fontSize: F.h1, fontWeight: 700, color: C.ink, margin: 0, textAlign: "center", lineHeight: 1.3 }}>
          ابقَ على اطلاع
        </h1>
        <p style={{ ...bodyFont, fontSize: F.body, color: C.secondary, lineHeight: 1.6, margin: `${S.sm}px 0 0`, textAlign: "center" }}>
          فعّل الإشعارات حتى لا يفوتك أي تحديث مهم. يمكنك تغيير هذا لاحقاً من الإعدادات.
        </p>
        <div style={{ height: S.xl }} />
        <div style={{ background: C.surface, borderRadius: R.lg, padding: `${S.xs}px ${S.lg}px`, boxShadow: E.card }}>
          <BenefitRow icon={<Timer size={22} />} title="اقتراب دورك" subtitle="نتابع تقدّم الدور ونُنبّهك عند اقترابه، لتتحرّك في الوقت المناسب." />
          <BenefitRow icon={<BadgeCheck size={22} />} title="تأكيد الحجز" subtitle="إشعار فوري عند تأكيد حجزك مع الطبيب." />
          <BenefitRow icon={<PauseCircle size={22} />} title="تغييرات الطبيب" subtitle="إذا أجّل الطبيب دوامه أو أوقفه مؤقتاً." last />
        </div>
      </div>
      <div style={{ padding: `${S.sm}px ${S.xxl}px ${S.xxl}px`, display: "flex", flexDirection: "column", gap: S.xs }}>
        <PrimaryButton label="تفعيل الإشعارات" icon={<BellRing size={18} />} onClick={onEnable} />
        <SecondaryButton label="ليس الآن" onClick={onMaybeLater} />
      </div>
    </div>
  );
}

/* =====================================================================
   Android permission dialog (mock)
===================================================================== */
function SystemPermissionDialog({ onAllow, onDeny }) {
  return (
    <div
      style={{
        position: "absolute", inset: 0, background: "rgba(0,0,0,0.5)",
        display: "flex", alignItems: "center", justifyContent: "center",
        zIndex: 50, borderRadius: 44,
        animation: "fadeIn 220ms ease-out",
      }}
    >
      <div
        style={{
          width: "84%", background: "#fff", borderRadius: R.xl, padding: `${S.xxl}px ${S.xl}px`,
          boxShadow: "0 20px 50px rgba(0,0,0,0.3)",
          animation: `popIn 320ms ${M.spring}`,
        }}
      >
        <div style={{ display: "flex", flexDirection: "row-reverse", alignItems: "center", gap: S.md, marginBottom: S.lg }}>
          <div style={{ width: 34, height: 34, borderRadius: 9, background: AURORA, flexShrink: 0 }} />
          <div style={{ ...bodyFont, fontSize: F.caption, fontWeight: 700, color: "#202124" }}>Medico</div>
        </div>
        <div style={{ ...bodyFont, fontSize: F.h3, fontWeight: 700, color: "#202124", lineHeight: 1.5, textAlign: "right" }}>
          هل تسمح لتطبيق Medico بإرسال الإشعارات؟
        </div>
        <div style={{ height: S.xl }} />
        <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
          <button
            onClick={onDeny}
            style={{
              ...bodyFont, fontWeight: 700, fontSize: F.body, color: "#5f6368",
              background: "none", border: "none", textAlign: "right",
              padding: `${S.md}px ${S.sm}px`, cursor: "pointer",
            }}
          >
            عدم السماح
          </button>
          <button
            onClick={onAllow}
            style={{
              ...bodyFont, fontWeight: 700, fontSize: F.body, color: "#1a73e8",
              background: "none", border: "none", textAlign: "right",
              padding: `${S.md}px ${S.sm}px`, cursor: "pointer",
            }}
          >
            السماح
          </button>
        </div>
      </div>
    </div>
  );
}

/* =====================================================================
   Completion (FIX 5: full wording)
===================================================================== */
function CompletionScreen({ onEnter, show }) {
  return (
    <div
      style={{
        height: "100%", position: "relative", overflow: "hidden",
        display: "flex", flexDirection: "column", alignItems: "center",
        justifyContent: "center", padding: `0 ${S.xxl}px`,
      }}
    >
      <div style={{ position: "absolute", top: 40, right: -30, width: 140, height: 140, borderRadius: "50%", background: C.tonal, opacity: 0.7 }} />
      <div style={{ position: "absolute", top: 90, left: -20, width: 100, height: 100, borderRadius: "50%", background: "#E4F0F7", opacity: 0.7 }} />
      <div style={{ position: "absolute", bottom: 60, left: -30, width: 180, height: 180, borderRadius: "50%", background: C.tonal, opacity: 0.5 }} />
      <div style={{ position: "absolute", bottom: 30, right: -20, width: 120, height: 120, borderRadius: "50%", background: "#E4F0F7", opacity: 0.5 }} />

      <div
        style={{
          width: 128, height: 128, borderRadius: "50%", background: AURORA,
          display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: "0 12px 32px rgba(29,158,117,0.35)",
          transform: show ? "scale(1)" : "scale(0)",
          transition: `transform 650ms ${M.spring}`,
        }}
      >
        <svg width="56" height="56" viewBox="0 0 56 56">
          <path
            d="M14 29 L23 37 L42 16"
            fill="none" stroke="#fff" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round"
            style={{
              strokeDasharray: 56,
              strokeDashoffset: show ? 0 : 56,
              transition: "stroke-dashoffset 500ms cubic-bezier(0.33,1,0.68,1) 400ms",
            }}
          />
        </svg>
      </div>

      <div
        style={{
          textAlign: "center", marginTop: S.xxxl,
          opacity: show ? 1 : 0,
          transform: show ? "translateY(0)" : "translateY(10px)",
          transition: "all 500ms ease-out 650ms",
        }}
      >
        <h1 style={{ ...displayFont, fontSize: F.h1, fontWeight: 700, color: C.ink, margin: 0, lineHeight: 1.3 }}>
          أنت جاهز الآن!
        </h1>
        <p style={{ ...bodyFont, fontSize: F.body, color: C.secondary, marginTop: S.md, lineHeight: 1.6 }}>
          ملفك الشخصي جاهز — رحلة العناية بصحتك تبدأ من هنا.
        </p>
      </div>

      <div
        style={{
          width: "100%", marginTop: 40,
          opacity: show ? 1 : 0,
          transition: "opacity 500ms ease-out 750ms",
        }}
      >
        <PrimaryButton label="الانتقال إلى الصفحة الرئيسية" onClick={onEnter} />
      </div>
    </div>
  );
}

/* =====================================================================
   Sheets
===================================================================== */
function SheetOverlay({ open, onClose, children }) {
  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 40, pointerEvents: open ? "auto" : "none" }}>
      <div
        onClick={onClose}
        style={{
          position: "absolute", inset: 0, background: "rgba(18,43,40,0.42)",
          opacity: open ? 1 : 0, transition: "opacity 250ms ease", borderRadius: 44,
        }}
      />
      <div
        style={{
          position: "absolute", left: 0, right: 0, bottom: 0, maxHeight: "78%",
          background: "#fff", borderRadius: `${R.xl}px ${R.xl}px 0 0`,
          boxShadow: E.sheet,
          transform: open ? "translateY(0)" : "translateY(100%)",
          transition: `transform 380ms cubic-bezier(0.33,1,0.68,1)`,
          display: "flex", flexDirection: "column",
        }}
      >
        {children}
      </div>
    </div>
  );
}

function SheetHandle() {
  return (
    <div style={{ display: "flex", justifyContent: "center", padding: `${S.md}px 0 ${S.sm}px` }}>
      <div style={{ width: 40, height: 4, borderRadius: R.pill, background: C.divider }} />
    </div>
  );
}

/* FIX 1 — year wheel: selected value stays fully visible, Arabic hint, تأكيد */
function YearSheet({ open, onClose, initial, onPick }) {
  const [selected, setSelected] = useState(initial || CURRENT_YEAR);
  const listRef = useRef(null);
  const ITEM_H = 46;
  const VIEW_H = 184;

  useEffect(() => {
    if (open && listRef.current) {
      const idx = Math.max(0, YEARS.indexOf(initial || CURRENT_YEAR));
      listRef.current.scrollTop = idx * ITEM_H;
      setSelected(YEARS[idx]);
    }
    // eslint-disable-next-line
  }, [open]);

  const handleScroll = () => {
    if (!listRef.current) return;
    const idx = Math.round(listRef.current.scrollTop / ITEM_H);
    setSelected(YEARS[Math.min(Math.max(idx, 0), YEARS.length - 1)]);
  };

  return (
    <SheetOverlay open={open} onClose={onClose}>
      <div style={{ padding: `0 ${S.xxl}px ${S.xxl}px`, display: "flex", flexDirection: "column", alignItems: "center" }}>
        <SheetHandle />
        <div style={{ ...displayFont, fontSize: F.h3, fontWeight: 700, color: C.ink, marginTop: S.sm }}>
          سنة الميلاد
        </div>
        <div style={{ height: S.xl }} />

        <div style={{ position: "relative", width: "100%", height: VIEW_H }}>
          {/* selection band sits BEHIND the list so the value is never covered */}
          <div
            style={{
              position: "absolute", top: "50%", left: 32, right: 32,
              transform: "translateY(-50%)", height: ITEM_H,
              background: C.tonal, borderRadius: R.sm, zIndex: 0, pointerEvents: "none",
            }}
          />
          <div
            ref={listRef}
            onScroll={handleScroll}
            style={{
              position: "relative", zIndex: 1,
              height: "100%", overflowY: "scroll", scrollSnapType: "y mandatory",
              padding: `${(VIEW_H - ITEM_H) / 2}px 0`,
              WebkitMaskImage: "linear-gradient(to bottom, transparent 0%, #000 34%, #000 66%, transparent 100%)",
              maskImage: "linear-gradient(to bottom, transparent 0%, #000 34%, #000 66%, transparent 100%)",
            }}
          >
            {YEARS.map((y) => {
              const active = y === selected;
              return (
                <div
                  key={y}
                  style={{
                    height: ITEM_H, display: "flex", alignItems: "center", justifyContent: "center",
                    scrollSnapAlign: "center",
                    ...(active ? displayFont : bodyFont),
                    fontSize: active ? F.h2 : F.bodyLg,
                    fontWeight: active ? 700 : 400,
                    color: active ? C.primary : C.muted,
                    transition: "color 160ms, font-size 160ms",
                  }}
                >
                  {y}
                </div>
              );
            })}
          </div>
        </div>

        <div style={{ height: S.xl }} />
        <div style={{ width: "100%" }}>
          <PrimaryButton label="تأكيد" onClick={() => onPick(selected)} />
        </div>
      </div>
    </SheetOverlay>
  );
}

function CitySheet({ open, onClose, current, onPick }) {
  return (
    <SheetOverlay open={open} onClose={onClose}>
      <div style={{ display: "flex", flexDirection: "column", maxHeight: "72vh" }}>
        <SheetHandle />
        <div style={{ padding: `${S.xs}px ${S.xxl}px ${S.md}px`, ...displayFont, fontSize: F.h3, fontWeight: 700, color: C.ink, textAlign: "right" }}>
          اختر محافظتك
        </div>
        <div style={{ overflowY: "auto", padding: `0 ${S.xl}px ${S.xl}px` }}>
          {GOVERNORATES.map((name) => {
            const selected = name === current;
            return (
              <button
                key={name}
                onClick={() => onPick(name)}
                style={{
                  width: "100%", padding: `${S.lg}px ${S.lg}px`, marginBottom: 2,
                  borderRadius: R.sm, border: "none",
                  background: selected ? C.tonal : "transparent",
                  display: "flex", flexDirection: "row-reverse", alignItems: "center",
                  cursor: "pointer", minHeight: 52,
                  transition: "background 180ms",
                }}
              >
                <span
                  style={{
                    ...bodyFont, fontSize: F.bodyLg,
                    fontWeight: selected ? 700 : 400,
                    color: selected ? C.primary : C.ink,
                    flex: 1, textAlign: "right",
                  }}
                >
                  {name}
                </span>
                {selected && <Check size={20} color={C.primary} />}
              </button>
            );
          })}
        </div>
      </div>
    </SheetOverlay>
  );
}

/* =====================================================================
   Root
===================================================================== */
export default function OnboardingPreview() {
  const [page, setPage] = useState(0);
  const [data, setData] = useState({ gender: null, birthYear: null, governorate: null });
  const [yearSheetOpen, setYearSheetOpen] = useState(false);
  const [citySheetOpen, setCitySheetOpen] = useState(false);
  const [systemDialogOpen, setSystemDialogOpen] = useState(false);
  const [checkShow, setCheckShow] = useState(false);

  const goTo = (p) => setPage(p);

  useEffect(() => {
    if (page === 3) {
      const t = setTimeout(() => setCheckShow(true), 80);
      return () => clearTimeout(t);
    }
    setCheckShow(false);
  }, [page]);

  return (
    <div style={{ minHeight: "100vh", background: "#EDF1EF", display: "flex", alignItems: "center", justifyContent: "center", padding: S.xxxl }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@500;600;700&family=Tajawal:wght@400;500;700&display=swap');
        * { box-sizing: border-box; }
        ::-webkit-scrollbar { display: none; }
        button:focus-visible { outline: 2px solid ${C.primaryBlue}; outline-offset: 2px; }
        @keyframes fadeIn { from { opacity: 0 } to { opacity: 1 } }
        @keyframes popIn { from { opacity: 0; transform: scale(0.92) } to { opacity: 1; transform: scale(1) } }
      `}</style>

      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: S.lg }}>
        <div style={{ ...bodyFont, fontSize: F.caption, fontWeight: 700, color: "#7c8985", letterSpacing: 0.4 }}>
          إعداد الحساب — اضغط للتفاعل
        </div>

        <div style={{ width: 390, height: 844, background: "#0c0c0c", borderRadius: 54, padding: 14, boxShadow: "0 30px 70px rgba(0,0,0,0.35)", position: "relative" }}>
          <div style={{ width: "100%", height: "100%", background: C.background, borderRadius: 40, overflow: "hidden", position: "relative" }}>
            <div
              style={{
                height: 28, display: "flex", flexDirection: "row-reverse",
                alignItems: "center", justifyContent: "space-between",
                padding: `0 ${S.xxl}px`, ...bodyFont, fontSize: F.micro, fontWeight: 700, color: C.ink,
              }}
            >
              <span>9:41</span>
              <span>●●●●</span>
            </div>

            <div style={{ height: "calc(100% - 28px)", position: "relative", overflow: "hidden", display: "flex", flexDirection: "column" }}>
              {/* Persistent shell header — never slides. The fill bar animates in
                  place while the pages move beneath it, so the two read as one motion. */}
              <StepHeader
                step={Math.min(page, 2)}
                visible={page < 3}
                onBack={page === 1 ? () => goTo(0) : page === 2 ? () => goTo(1) : null}
              />
              <div style={{ flex: 1, position: "relative", overflow: "hidden" }}>
              <div
                style={{
                  display: "flex", width: "400%", height: "100%",
                  // Pages are laid out in reverse (step 1 is the RIGHTMOST child),
                  // so advancing shifts the track to the RIGHT and each new screen
                  // enters from the LEFT — the natural "forward" direction in Arabic.
                  transform: `translateX(-${(3 - page) * 25}%)`,
                  transition: `transform ${M.page}`,
                }}
              >
                <div style={{ width: "25%", height: "100%", opacity: page === 3 ? 1 : 0.55, transition: "opacity 520ms ease" }}>
                  <CompletionScreen onEnter={() => goTo(0)} show={checkShow} />
                </div>
                <div style={{ width: "25%", height: "100%", opacity: page === 2 ? 1 : 0.55, transition: "opacity 520ms ease" }}>
                  <Step3 onEnable={() => setSystemDialogOpen(true)} onMaybeLater={() => goTo(3)} />
                </div>
                <div style={{ width: "25%", height: "100%", opacity: page === 1 ? 1 : 0.55, transition: "opacity 520ms ease" }}>
                  <Step2 data={data} onContinue={() => goTo(2)} openCitySheet={() => setCitySheetOpen(true)} />
                </div>
                <div style={{ width: "25%", height: "100%", opacity: page === 0 ? 1 : 0.55, transition: "opacity 520ms ease" }}>
                  <Step1
                    data={data}
                    setData={setData}
                    onContinue={() => goTo(1)}
                    onSkip={() => goTo(1)}
                    openYearSheet={() => setYearSheetOpen(true)}
                  />
                </div>
              </div>
              </div>

              <YearSheet
                open={yearSheetOpen}
                initial={data.birthYear}
                onClose={() => setYearSheetOpen(false)}
                onPick={(y) => { setData({ ...data, birthYear: y }); setYearSheetOpen(false); }}
              />
              <CitySheet
                open={citySheetOpen}
                current={data.governorate}
                onClose={() => setCitySheetOpen(false)}
                onPick={(name) => { setData({ ...data, governorate: name }); setCitySheetOpen(false); }}
              />
              {systemDialogOpen && (
                <SystemPermissionDialog
                  onAllow={() => { setSystemDialogOpen(false); goTo(3); }}
                  onDeny={() => { setSystemDialogOpen(false); goTo(3); }}
                />
              )}
            </div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "row-reverse", gap: S.sm }}>
          {[0, 1, 2, 3].map((i) => (
            <button
              key={i}
              onClick={() => goTo(i)}
              style={{
                width: 32, height: 32, borderRadius: "50%", border: "none",
                background: page === i ? AURORA : "#fff",
                color: page === i ? "#fff" : C.secondary,
                ...bodyFont, fontSize: F.caption, fontWeight: 700, cursor: "pointer",
                boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
              }}
            >
              {i + 1}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
