import 'dart:math';
import '../models/provider_model.dart';
import '../models/agent_log.dart';
import '../data/market_rates.dart';

class MolBhaavAgent {
  static final _rng = Random();

  static NegotiationResult negotiate(ServiceProvider provider, String serviceType) {
    final rates = getRateFor(serviceType);
    final rounds = <NegotiationRound>[];

    // Simulate provider's inflated initial quote (10–25% above market max)
    final quoteVariance = 1.10 + _rng.nextDouble() * 0.15;
    final providerQuote = (provider.priceMax * quoteVariance).round();

    rounds.add(NegotiationRound(
      round: 0,
      actor: 'provider',
      amount: providerQuote,
      action: 'quoted',
      note: providerQuote > rates.max ? 'Above market rate' : 'Within market range',
    ));

    // Rule 1: If within market range → accept immediately
    if (providerQuote <= rates.max) {
      return NegotiationResult(
        providerName: provider.name,
        serviceType: serviceType,
        marketMin: rates.min,
        marketMax: rates.max,
        providerQuote: providerQuote,
        rounds: rounds,
        finalPrice: providerQuote,
        savings: 0,
        savingsPercent: 0,
        outcome: 'ACCEPTED',
        movedToNext: false,
        explanation: 'Provider ka rate Rs. ${_fmt(providerQuote)} already market range (Rs. ${_fmt(rates.min)}–${_fmt(rates.max)}) mein hai. Fair price! ✅',
      );
    }

    // Rule 2: Counter with market_max + 10%
    final counterOffer = max((rates.max * 1.10).round(), rates.min);
    rounds.add(NegotiationRound(
      round: 1,
      actor: 'agent',
      amount: counterOffer,
      action: 'countered',
      note: 'Market rate Rs. ${_fmt(rates.min)}–${_fmt(rates.max)} + 10%',
    ));

    // Simulate provider response
    final gap = providerQuote - counterOffer;
    final concession = (gap * (0.4 + _rng.nextDouble() * 0.2)).round();
    final providerCounter1 = providerQuote - concession;

    if (providerCounter1 <= counterOffer) {
      rounds.add(NegotiationRound(
        round: 1, actor: 'provider', amount: counterOffer,
        action: 'accepted', note: 'Provider agreed to counter-offer',
      ));
      final savings = providerQuote - counterOffer;
      return NegotiationResult(
        providerName: provider.name,
        serviceType: serviceType,
        marketMin: rates.min, marketMax: rates.max,
        providerQuote: providerQuote, rounds: rounds,
        finalPrice: counterOffer, savings: savings,
        savingsPercent: ((savings / providerQuote) * 100).round(),
        outcome: 'NEGOTIATED', movedToNext: false,
        explanation: 'Provider ne Rs. ${_fmt(providerQuote)} maanga tha. Humne Rs. ${_fmt(counterOffer)} counter kiya aur maan gaya! Aapne Rs. ${_fmt(savings)} bachaye! 🎉',
      );
    }

    rounds.add(NegotiationRound(
      round: 1, actor: 'provider', amount: providerCounter1,
      action: 'countered', note: 'Provider came down from Rs. ${_fmt(providerQuote)}',
    ));

    // Rule 3: Split the difference (round 2)
    final midpoint = max(((counterOffer + providerCounter1) / 2).round(), rates.min);
    rounds.add(NegotiationRound(
      round: 2, actor: 'agent', amount: midpoint,
      action: 'countered', note: 'Splitting the difference — fair compromise',
    ));

    final accepted = _rng.nextDouble() < 0.80 || midpoint >= providerCounter1;
    if (accepted) {
      rounds.add(NegotiationRound(
        round: 2, actor: 'provider', amount: midpoint,
        action: 'accepted', note: 'Deal finalized',
      ));
      final savings = providerQuote - midpoint;
      return NegotiationResult(
        providerName: provider.name,
        serviceType: serviceType,
        marketMin: rates.min, marketMax: rates.max,
        providerQuote: providerQuote, rounds: rounds,
        finalPrice: midpoint, savings: savings,
        savingsPercent: ((savings / providerQuote) * 100).round(),
        outcome: 'NEGOTIATED', movedToNext: false,
        explanation: '2 rounds ki negotiation ke baad deal ho gayi Rs. ${_fmt(midpoint)} par! Aapne Rs. ${_fmt(savings)} (${((savings / providerQuote) * 100).round()}%) bachaye! 🎉',
      );
    }

    rounds.add(NegotiationRound(
      round: 2, actor: 'provider', amount: providerCounter1,
      action: 'rejected', note: 'Provider did not agree — moving to next',
    ));

    return NegotiationResult(
      providerName: provider.name,
      serviceType: serviceType,
      marketMin: rates.min, marketMax: rates.max,
      providerQuote: providerQuote, rounds: rounds,
      finalPrice: 0, savings: 0, savingsPercent: 0,
      outcome: 'REJECTED', movedToNext: true,
      explanation: 'Provider Rs. ${_fmt(providerCounter1)} se neeche nahi aaya. No deal after 2 rounds. Moving to next provider...',
    );
  }

  static String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
