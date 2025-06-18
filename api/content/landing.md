# CHOIR.CHAT

<div class="choir-hero-section">
  <h2>A New Era of Collaborative Intelligence</h2>
  <p class="choir-tagline">Where your ideas and insights are truly valued, rewarded, and amplified.</p>
  <div class="choir-cta-buttons">
    <a href="https://testflight.apple.com/join/bDv6gSEB" class="choir-cta-button choir-primary">Get iOS TestFlight</a>
  </div>
</div>

<div class="choir-features-grid">
  <div class="choir-feature-card">
    <h3>Why Choir?</h3>
    <p>Choir represents a paradigm shift in how we interact with AI and each other. By orchestrating multiple AI models working in concert, we create a more balanced, nuanced, and reliable platform for knowledge sharing and creation.</p>
  </div>

  <div class="choir-feature-card">
    <h3>Why Multi-Agent?</h3>
    <p>Trust emerges from consensus. Our diverse portfolio of AI models provides multiple perspectives, reducing bias and increasing reliability. When multiple independent agents agree, you can trust the result.</p>
  </div>

  <div class="choir-feature-card">
    <h3>Why Anonymity?</h3>
    <p>Clarity of thought requires freedom from social surveillance. On Choir, ideas stand on their own merit, not on who said them. Express yourself freely without fear of judgment or social consequences.</p>
  </div>

  <div class="choir-feature-card">
    <h3>Why Rewards?</h3>
    <p>Unlike other platforms where your likes and followers are valuable but not yours, Choir turns posting into value creation. Earn transferable CHOIR tokens for quality contributions, then stake them in relationships that matter. Your intellectual value belongs to you.</p>
  </div>

  <div class="choir-feature-card">
    <h3>Why Pages?</h3>
    <p>Scrolling is a mind-killer. Our page-based structure creates focused, digestible content units that enhance engagement and comprehension, moving beyond the endless scroll of traditional platforms.</p>
  </div>

  <div class="choir-feature-card">
    <h3>Why Blockchain?</h3>
    <p>Our AI-native transaction ledger provides transparency and reinforces trust. Blockchain technology ensures that contributions are immutably recorded and fairly rewarded, creating a new socioeconomic media paradigm.</p>
  </div>
</div>

<div class="choir-future-section">
  <h2>The Future of Choir</h2>
  <p>We're building a dynamic, collaborative platform that will continue to evolve with these exciting features:</p>

  <div class="choir-future-features">
    <div class="choir-future-feature">
      <h4>Relationship Staking</h4>
      <p>Invest your earned CHOIR tokens directly into meaningful connections. Stake tokens to respond to someone's idea—they can engage and lock tokens into a shared relationship, or ignore you and keep them. Real skin in the game for quality discourse.</p>
    </div>

    <div class="choir-future-feature">
      <h4>Multiparty Relationships</h4>
      <p>Form groups with shared token pools. Members can exit unilaterally, taking their share, creating dynamic communities with real economic alignment.</p>
    </div>

    <div class="choir-future-feature">
      <h4>Multimodality</h4>
      <p>Voice, image, and eventually video input/output will create more natural and versatile human-AI interactions.</p>
    </div>

    <div class="choir-future-feature">
      <h4>Local Embeddings</h4>
      <p>Enhanced contextual understanding through localized knowledge representation.</p>
    </div>

    <div class="choir-future-feature">
      <h4>Per-User Memory</h4>
      <p>Personalized experiences that remember your preferences and past interactions.</p>
    </div>

    <div class="choir-future-feature">
      <h4>Like Minds Discovery</h4>
      <p>AI identifies intellectual compatibility through citation patterns and conversation quality, introducing you to kindred spirits based on merit, not metrics.</p>
    </div>
  </div>
</div>

<div class="choir-cta-section">
  <h2>Experience Choir</h2>
  <p>Use a platform that values intelligence, rewards contributions, and creates a more thoughtful digital ecosystem.</p>
  <div class="choir-cta-buttons">
    <a href="https://testflight.apple.com/join/bDv6gSEB" class="choir-cta-button choir-primary">Download on iOS</a>
  </div>
</div>

<style>
.choir-hero-section {
  text-align: center;
  padding: 3rem 1rem;
  margin-bottom: 2rem;
  background: linear-gradient(135deg, rgba(13, 13, 13, 0.95), rgba(26, 26, 26, 0.9));
  color: var(--text-color-primary, #f5f5f5);
  border-radius: var(--border-radius-lg, 20px);
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.8);
  position: relative;
  overflow: hidden;
  /* Carbon fiber texture */
  background-image:
    linear-gradient(45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%),
    linear-gradient(-45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%);
  background-size: 4px 4px, 4px 4px;
}

.choir-hero-section::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: var(--border-radius-lg, 20px);
  padding: 2px;
  background:
    /* Irregular patina border with breaks */
    linear-gradient(90deg,
      #ffd700 0%, #ffd700 12%, transparent 12%, transparent 18%,
      #c0c0c0 18%, #c0c0c0 32%, transparent 32%, transparent 38%,
      #e5e4e2 38%, #e5e4e2 55%, transparent 55%, transparent 62%,
      #b87333 62%, #b87333 78%, transparent 78%, transparent 85%,
      #ffd700 85%, #ffd700 100%);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  mask-composite: exclude;
  opacity: 0.4;
  z-index: -1;
}

/* Remove crack overlay from hero section */

.choir-hero-section h2 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
  background: linear-gradient(90deg, #ffd700, #c0c0c0, #e5e4e2);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  display: inline-block;
  text-shadow: 0 0 15px rgba(255, 215, 0, 0.3);
  position: relative;
  z-index: 2;
}

.choir-tagline {
  font-size: 1.2rem;
  margin-bottom: 2rem;
  max-width: 800px;
  margin-left: auto;
  margin-right: auto;
  color: var(--text-color-secondary, #a8a8a8);
  position: relative;
  z-index: 2;
}

.choir-cta-buttons {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin: 2rem 0;
}

.choir-cta-button {
  display: inline-block;
  padding: 0.8rem 1.5rem;
  border-radius: 30px;
  font-weight: bold;
  text-decoration: none;
  transition: all 0.3s ease;
}

.choir-cta-button.choir-primary {
  background: linear-gradient(135deg, rgba(13, 13, 13, 0.95), rgba(26, 26, 26, 0.9));
  color: #f5f5f5;
  border: 1px solid rgba(192, 192, 192, 0.3);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.8);
  position: relative;
  overflow: hidden;
  /* Carbon fiber texture */
  background-image:
    linear-gradient(45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%),
    linear-gradient(-45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%);
  background-size: 2px 2px, 2px 2px;
}

.choir-cta-button.choir-primary::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, rgba(255, 215, 0, 0.1), rgba(192, 192, 192, 0.08));
  opacity: 0;
  transition: opacity 0.4s ease;
}

.choir-cta-button.choir-primary:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 25px rgba(0, 0, 0, 0.9);
  border-color: #ffd700;
  color: #ffd700;
  text-shadow: 0 0 8px rgba(255, 215, 0, 0.4);
}

.choir-cta-button.choir-primary:hover::before {
  opacity: 1;
}

.choir-features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin: 3rem 0;
}

.choir-feature-card {
  background: rgba(13, 13, 13, 0.95);
  border-radius: var(--border-radius-md, 16px);
  padding: 1.5rem;
  box-shadow: 0 8px 15px rgba(0, 0, 0, 0.8);
  transition: transform 0.4s ease, box-shadow 0.4s ease;
  border: 1px solid rgba(128, 128, 128, 0.3);
  position: relative;
  /* Carbon fiber texture */
  background-image:
    linear-gradient(90deg, rgba(0, 0, 0, 0.9) 50%, rgba(128, 128, 128, 0.05) 50%),
    linear-gradient(0deg, rgba(0, 0, 0, 0.9) 50%, rgba(128, 128, 128, 0.05) 50%);
  background-size: 2px 2px, 2px 2px;
}

.choir-feature-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 15px 30px rgba(0, 0, 0, 0.9);
  border-color: rgba(255, 215, 0, 0.5);
}

.choir-feature-card h3 {
  background: linear-gradient(90deg, #ffd700, #c0c0c0);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  margin-bottom: 1rem;
  font-size: 1.4rem;
  display: inline-block;
  text-shadow: 0 0 10px rgba(255, 215, 0, 0.2);
}

.choir-feature-card p {
  color: #a8a8a8;
}

.choir-future-section {
  background: rgba(13, 13, 13, 0.95);
  padding: 3rem 2rem;
  border-radius: var(--border-radius-lg, 20px);
  margin: 3rem 0;
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.8);
  position: relative;
  /* Carbon fiber texture */
  background-image:
    linear-gradient(45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%),
    linear-gradient(-45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%);
  background-size: 4px 4px, 4px 4px;
}

.choir-future-section::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: var(--border-radius-lg, 20px);
  padding: 2px;
  background:
    /* Irregular silver patina border */
    linear-gradient(45deg,
      #c0c0c0 0%, #c0c0c0 15%, transparent 15%, transparent 22%,
      #e5e4e2 22%, #e5e4e2 40%, transparent 40%, transparent 48%,
      #b87333 48%, #b87333 65%, transparent 65%, transparent 72%,
      #808080 72%, #808080 88%, transparent 88%, transparent 95%,
      #c0c0c0 95%, #c0c0c0 100%);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  mask-composite: exclude;
  opacity: 0.3;
  z-index: -1;
}

/* Remove the prominent diagonal line from future section */

.choir-future-section h2 {
  text-align: center;
  margin-bottom: 2rem;
  background: linear-gradient(90deg, #c0c0c0, #e5e4e2);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  display: inline-block;
  margin-left: auto;
  margin-right: auto;
  width: fit-content;
  text-shadow: 0 0 12px rgba(192, 192, 192, 0.3);
  position: relative;
  z-index: 2;
}

.choir-future-features {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  position: relative;
  z-index: 2;
}

.choir-future-feature {
  background: rgba(26, 26, 26, 0.9);
  padding: 1.5rem;
  border-radius: var(--border-radius-sm, 12px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.6);
  transition: transform 0.4s ease;
  border: 1px solid rgba(128, 128, 128, 0.2);
  /* Subtle carbon fiber texture */
  background-image:
    linear-gradient(90deg, rgba(0, 0, 0, 0.9) 50%, rgba(128, 128, 128, 0.03) 50%);
  background-size: 1px 1px;
}

.choir-future-feature:hover {
  transform: translateY(-5px);
  border-color: rgba(255, 215, 0, 0.4);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.8);
}

.choir-future-feature h4 {
  color: #e5e4e2;
  margin-bottom: 0.5rem;
  text-shadow: 0 0 6px rgba(229, 228, 226, 0.2);
}

.choir-future-feature p {
  color: #a8a8a8;
}

.choir-cta-section {
  text-align: center;
  padding: 3rem 1rem;
  background: linear-gradient(135deg, rgba(13, 13, 13, 0.95), rgba(26, 26, 26, 0.9));
  color: var(--text-color-primary, #f5f5f5);
  border-radius: var(--border-radius-lg, 20px);
  margin-top: 3rem;
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.8);
  position: relative;
  overflow: hidden;
  /* Carbon fiber texture */
  background-image:
    linear-gradient(45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%),
    linear-gradient(-45deg, rgba(0, 0, 0, 0.9) 25%, transparent 25%);
  background-size: 4px 4px, 4px 4px;
}

.choir-cta-section::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border-radius: var(--border-radius-lg, 20px);
  padding: 2px;
  background:
    /* Irregular platinum patina border */
    linear-gradient(135deg,
      #e5e4e2 0%, #e5e4e2 18%, transparent 18%, transparent 25%,
      #ffd700 25%, #ffd700 42%, transparent 42%, transparent 48%,
      #c0c0c0 48%, #c0c0c0 65%, transparent 65%, transparent 72%,
      #b87333 72%, #b87333 85%, transparent 85%, transparent 92%,
      #e5e4e2 92%, #e5e4e2 100%);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  mask-composite: exclude;
  opacity: 0.4;
  z-index: -1;
}

/* Remove the prominent diagonal line from CTA section */

.choir-cta-section h2 {
  margin-bottom: 1rem;
  background: linear-gradient(90deg, #ffd700, #c0c0c0, #e5e4e2);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  display: inline-block;
  text-shadow: 0 0 15px rgba(255, 215, 0, 0.3);
  position: relative;
  z-index: 2;
}

.choir-cta-section p {
  color: #a8a8a8;
  position: relative;
  z-index: 2;
}

@media (max-width: 768px) {
  .choir-features-grid, .choir-future-features {
    grid-template-columns: 1fr;
  }

  .choir-hero-section h2 {
    font-size: 2rem;
  }
}
</style>
