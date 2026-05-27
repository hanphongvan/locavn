import { ChangeDetectionStrategy, Component } from '@angular/core';

interface MapNode {
  x: number;
  y: number;
  color: string;
  r: number;
  pulse?: boolean;
}

/** Bản đồ Việt Nam + overlay HUD — cùng viewBox 812×873. */
@Component({
  selector: 'app-login-vietnam-map',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="vn-map" aria-hidden="true">
      <div class="vn-map__hud">
        <span class="material-icons vn-map__satellite">satellite_alt</span>
      </div>

      <svg
        class="vn-map__svg"
        viewBox="0 0 812 873"
        preserveAspectRatio="xMidYMid meet"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <filter id="vn-node-glow">
            <feGaussianBlur stdDeviation="3" result="b" />
            <feMerge>
              <feMergeNode in="b" />
              <feMergeNode in="SourceGraphic" />
            </feMerge>
          </filter>
        </defs>

        <!-- Lớp nền: bản đồ tỉnh thành (cùng hệ tọa độ) -->
        <image
          class="vn-map__country"
          href="assets/auth/vietnam-map.svg"
          x="0"
          y="0"
          width="812"
          height="873"
          preserveAspectRatio="xMidYMid meet"
        />

        <!-- Mạng lưới + điểm dữ liệu — tọa độ trên lãnh thổ VN -->
        <path
          class="vn-map__network"
          d="M 248 128 L 202 118 L 160 255 L 298 420 L 328 548 L 228 698 L 198 748
             M 248 128 L 160 255 M 160 255 L 298 420 M 298 420 L 328 548
             M 328 548 L 228 698 M 228 698 L 198 748"
          stroke="#38bdf8"
          stroke-width="1.2"
          stroke-dasharray="5 7"
          fill="none"
          opacity="0.55"
        />

        @for (node of nodes; track node.x) {
          <circle
            class="vn-map__node"
            [class.vn-map__node--pulse]="node.pulse"
            [attr.cx]="node.x"
            [attr.cy]="node.y"
            [attr.r]="node.r"
            [attr.fill]="node.color"
            [attr.filter]="node.pulse ? 'url(#vn-node-glow)' : null"
          />
        }

        <g class="vn-map__islands">
          <circle cx="620" cy="340" r="4" fill="#7dd3fc" opacity="0.85" />
          <text x="628" y="344" class="vn-map__island-label">Hoàng Sa</text>
          <circle cx="640" cy="580" r="4" fill="#7dd3fc" opacity="0.85" />
          <text x="592" y="584" class="vn-map__island-label">Trường Sa</text>
        </g>
      </svg>

      @for (p of particles; track p.id) {
        <span
          class="vn-map__particle"
          [style.left.%]="p.x"
          [style.top.%]="p.y"
          [style.animation-delay.s]="p.delay"
        ></span>
      }
    </div>
  `,
  styles: `
    :host {
      display: block;
      width: 100%;
    }

    .vn-map {
      position: relative;
      width: 100%;
      max-width: 26rem;
      margin: 0 auto;
    }

    .vn-map__hud {
      position: absolute;
      top: 0;
      right: 0;
      z-index: 2;
      pointer-events: none;
    }

    .vn-map__satellite {
      font-size: 1.75rem !important;
      color: #7dd3fc;
      opacity: 0.85;
      animation: vn-satellite-pulse 3s ease-in-out infinite;
    }

    @keyframes vn-satellite-pulse {
      0%,
      100% {
        opacity: 0.6;
        transform: scale(1);
      }
      50% {
        opacity: 1;
        transform: scale(1.06);
      }
    }

    .vn-map__svg {
      display: block;
      width: 100%;
      height: auto;
      overflow: visible;
      filter: drop-shadow(0 0 14px rgba(56, 189, 248, 0.4));
      animation: vn-map-glow-pulse 4s ease-in-out infinite;
    }

    @keyframes vn-map-glow-pulse {
      0%,
      100% {
        filter: drop-shadow(0 0 10px rgba(56, 189, 248, 0.35));
      }
      50% {
        filter: drop-shadow(0 0 22px rgba(56, 189, 248, 0.6));
      }
    }

    .vn-map__country {
      pointer-events: none;
    }

    .vn-map__network {
      animation: vn-dash 22s linear infinite;
    }

    @keyframes vn-dash {
      to {
        stroke-dashoffset: -96;
      }
    }

    .vn-map__node--pulse {
      animation: vn-node-blink 2.2s ease-in-out infinite;
    }

    @keyframes vn-node-blink {
      0%,
      100% {
        opacity: 1;
      }
      50% {
        opacity: 0.4;
      }
    }

    .vn-map__island-label {
      font-size: 11px;
      fill: rgba(186, 230, 253, 0.8);
      font-family: var(--app-font-sans, sans-serif);
      font-weight: 600;
    }

    .vn-map__particle {
      position: absolute;
      width: 3px;
      height: 3px;
      border-radius: 50%;
      background: #7dd3fc;
      box-shadow: 0 0 6px #38bdf8;
      animation: vn-particle-float 8s ease-in-out infinite;
      opacity: 0.6;
      z-index: 1;
      pointer-events: none;
    }

    @keyframes vn-particle-float {
      0%,
      100% {
        transform: translate(0, 0);
        opacity: 0.2;
      }
      50% {
        transform: translate(12px, -18px);
        opacity: 0.85;
      }
    }
  `,
})
export class LoginVietnamMapComponent {
  /** Tọa độ theo viewBox bản đồ @svg-maps/vietnam (812×873). */
  readonly nodes: MapNode[] = [
    { x: 248, y: 128, color: '#3b82f6', r: 6 }, // Chợ
    { x: 202, y: 118, color: '#14b8a6', r: 5 }, // Cửa hàng tiện lợi
    { x: 160, y: 255, color: '#a855f7', r: 5 }, // Trung tâm thương mại
    { x: 298, y: 420, color: '#f97316', r: 6, pulse: true }, // Trung tâm logistics
    { x: 328, y: 548, color: '#22c55e', r: 5 }, // Siêu thị
    { x: 228, y: 698, color: '#ec4899', r: 6 }, // Cửa hàng xăng dầu
    { x: 198, y: 748, color: '#eab308', r: 5 }, // Cửa hàng OCOP
  ];

  readonly particles = [
    { id: 1, x: 18, y: 15, delay: 0 },
    { id: 2, x: 72, y: 28, delay: 1.2 },
    { id: 3, x: 38, y: 52, delay: 2.4 },
    { id: 4, x: 82, y: 68, delay: 0.8 },
    { id: 5, x: 24, y: 78, delay: 3.1 },
  ];
}
