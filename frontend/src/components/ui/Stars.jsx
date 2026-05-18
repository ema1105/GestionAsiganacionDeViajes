import { IconStar } from '../icons/Icons.jsx';

// Estrellas doradas reutilizables (1-5). `value` puede ser decimal.
export default function Stars({ value = 0 }) {
  const v = Math.round(value);
  return (
    <span className="inline-flex gap-0.5" aria-label={`${value} de 5`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <IconStar key={i} filled={i <= v} />
      ))}
    </span>
  );
}
