// =====================================================================
//  Reusable Neo-Brutalist React components
// =====================================================================
import React from "react";
import { ChevronRight } from "lucide-react";

export function NeoCard({ children, className = "", style, onClick, color, padding = 18 }) {
  return (
    <div
      className={`nb-block ${onClick ? "sensor-card" : ""} ${className}`}
      style={{ padding, background: color, ...style }}
      onClick={onClick}
      data-testid={onClick ? "neo-card-clickable" : undefined}
    >
      {children}
    </div>
  );
}

export function NeoButton({
  children,
  onClick,
  variant = "yellow",
  fullWidth,
  icon: Icon,
  className = "",
  type = "button",
  testId,
}) {
  const map = {
    yellow: "nb-btn",
    blue: "nb-btn nb-btn--blue",
    mint: "nb-btn nb-btn--mint",
    red: "nb-btn nb-btn--red",
    ink: "nb-btn nb-btn--ink",
    white: "nb-btn nb-btn--white",
  };
  return (
    <button
      type={type}
      className={`${map[variant]} ${className}`}
      onClick={onClick}
      style={fullWidth ? { width: "100%" } : undefined}
      data-testid={testId}
    >
      {Icon && <Icon size={16} strokeWidth={2.5} />}
      <span>{children}</span>
    </button>
  );
}

export function NeoTag({ label, variant = "yellow", icon: Icon, size = 11 }) {
  const map = {
    yellow: "nb-tag",
    error: "nb-tag nb-tag--error",
    info: "nb-tag nb-tag--info",
    success: "nb-tag nb-tag--success",
    ink: "nb-tag nb-tag--ink",
  };
  return (
    <span className={map[variant]} style={{ fontSize: size }}>
      {Icon && <Icon size={size + 2} strokeWidth={2.5} />}
      {label}
    </span>
  );
}

export function NeoIconBox({ icon: Icon, color = "var(--nb-yellow)", size = 44, iconSize = 22, onClick, iconColor = "var(--nb-ink)", className = "", testId }) {
  return (
    <button
      type="button"
      className={`nb-iconbox ${className}`}
      style={{ width: size, height: size, background: color }}
      onClick={onClick}
      data-testid={testId}
      tabIndex={onClick ? 0 : -1}
    >
      <Icon size={iconSize} color={iconColor} strokeWidth={2.5} />
    </button>
  );
}

export function NeoSectionHeader({ label, trailing }) {
  return (
    <div style={{ marginBottom: 10 }}>
      <div className="row-between">
        <h3 className="font-display" style={{ margin: 0, fontSize: 14 }}>
          {label}
        </h3>
        {trailing}
      </div>
      <div style={{ height: 2.5, background: "var(--nb-ink)", marginTop: 6 }} />
    </div>
  );
}

export function NeoListItem({ icon: Icon, color = "var(--nb-yellow)", title, subtitle, onClick, textColor = "var(--nb-ink)" }) {
  return (
    <div
      onClick={onClick}
      className="nb-block"
      style={{
        background: color,
        padding: "10px 14px",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: 12,
        boxShadow: "var(--nb-shadow)",
        transition: "transform 100ms ease, box-shadow 100ms ease",
      }}
      onMouseEnter={(e) => (e.currentTarget.style.transform = "translate(-2px,-2px)")}
      onMouseLeave={(e) => (e.currentTarget.style.transform = "translate(0,0)")}
    >
      <div
        style={{
          width: 36, height: 36,
          background: "var(--nb-white)", border: "2px solid var(--nb-ink)",
          borderRadius: 4, display: "flex", alignItems: "center", justifyContent: "center",
        }}
      >
        <Icon size={18} color="var(--nb-ink)" strokeWidth={2.5} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="font-label" style={{ fontSize: 13, color: textColor, marginBottom: 2 }}>
          {title}
        </div>
        <div className="font-label" style={{ fontSize: 9.5, color: textColor, opacity: 0.75 }}>
          {subtitle}
        </div>
      </div>
      <ChevronRight size={18} color={textColor} strokeWidth={2.5} />
    </div>
  );
}

// Smooth ease-out tween that animates a number when `value` changes (~0.8s)
export function AnimatedNumber({ value, decimals = 1, duration = 800, fontStyle }) {
  const [display, setDisplay] = React.useState(value || 0);
  const fromRef = React.useRef(value || 0);
  const startRef = React.useRef(null);
  const rafRef = React.useRef(null);

  React.useEffect(() => {
    cancelAnimationFrame(rafRef.current);
    fromRef.current = display;
    startRef.current = null;
    const target = Number(value) || 0;

    const tick = (ts) => {
      if (!startRef.current) startRef.current = ts;
      const elapsed = ts - startRef.current;
      const t = Math.min(elapsed / duration, 1);
      // easeOutCubic
      const eased = 1 - Math.pow(1 - t, 3);
      const next = fromRef.current + (target - fromRef.current) * eased;
      setDisplay(next);
      if (t < 1) rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(rafRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  return <span className="tween font-mono" style={fontStyle}>{Number(display).toFixed(decimals)}</span>;
}
