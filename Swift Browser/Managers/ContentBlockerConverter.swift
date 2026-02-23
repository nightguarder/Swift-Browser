//
//  ContentBlockerConverter.swift
//  Swift Browser
//
//  Converts AdGuard filter syntax to WKContentRuleList JSON format
//

import Foundation

final class ContentBlockerConverter {
    
    struct ConversionResult {
        let json: String
        let ruleCount: Int
        let errors: [String]
    }
    
    private let maxRulesPerList = 50000
    
    func convert(filterContent: String, maxRules: Int? = nil) -> ConversionResult {
        let lines = filterContent.components(separatedBy: .newlines)
        var rules: [[String: Any]] = []
        var errors: [String] = []
        
        let limit = maxRules ?? maxRulesPerList
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty { continue }
            if trimmed.hasPrefix("!") { continue }
            if trimmed.hasPrefix("[") { continue }
            
            if trimmed.hasPrefix("@@") {
                if let rule = parseExceptionRule(trimmed) {
                    if rules.count < limit {
                        rules.append(rule)
                    }
                } else {
                    errors.append("Failed to parse exception: \(trimmed)")
                }
            } else if trimmed.contains("##") {
                if let rule = parseCSSHideRule(trimmed) {
                    if rules.count < limit {
                        rules.append(rule)
                    }
                }
            } else if let rule = parseBlockingRule(trimmed) {
                if rules.count < limit {
                    rules.append(rule)
                }
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: rules, options: [.prettyPrinted, .sortedKeys])
            let json = String(data: jsonData, encoding: .utf8) ?? "[]"
            return ConversionResult(json: json, ruleCount: rules.count, errors: errors)
        } catch {
            return ConversionResult(json: "[]", ruleCount: 0, errors: [error.localizedDescription])
        }
    }
    
    private func parseBlockingRule(_ line: String) -> [String: Any]? {
        var urlFilter = line
        var resourceTypes: [String]? = nil
        var loadType: String? = nil
        var domains: [String]? = nil
        var unlessDomains: [String]? = nil
        
        if let domainIndex = line.range(of: "$domain=") {
            let domainPart = String(line[domainIndex.upperBound...])
            let components = domainPart.components(separatedBy: "$")
            let domainString = components[0]
            
            domains = domainString.components(separatedBy: ",")
            
            urlFilter = String(line[..<domainIndex.lowerBound])
            urlFilter = urlFilter.replacingOccurrences(of: "$", with: "")
        }
        
        if let typeIndex = line.range(of: "$") {
            let typePart = String(line[typeIndex.upperBound...])
            var types: [String] = []
            
            if typePart.contains("script") { types.append("script") }
            if typePart.contains("image") { types.append("image") }
            if typePart.contains("stylesheet") { types.append("style-sheet") }
            if typePart.contains("xmlhttprequest") || typePart.contains("xhr") { types.append("xmlhttprequest") }
            if typePart.contains("font") { types.append("font") }
            if typePart.contains("websocket") { types.append("websocket") }
            if typePart.contains("ping") { types.append("ping") }
            if typePart.contains("document") { types.append("document") }
            if typePart.contains("popup") { types.append("popup") }
            
            if !types.isEmpty {
                resourceTypes = types
            }
            
            if typePart.contains("third-party") {
                loadType = "third-party"
            } else if typePart.contains("first-party") {
                loadType = "first-party"
            }
            
            if typePart.contains("denyallow=") {
                if let denyRange = typePart.range(of: "denyallow=") {
                    let denyPart = String(typePart[denyRange.upperBound...])
                    let denyDomains = denyPart.components(separatedBy: ",").map { escapeDomain($0) }
                    unlessDomains = denyDomains
                }
            }
        }
        
        let urlFilterRegex = convertToRegex(urlFilter)
        
        var trigger: [String: Any] = ["url-filter": urlFilterRegex]
        
        if let types = resourceTypes, !types.isEmpty {
            trigger["resource-type"] = types
        }
        
        if let load = loadType {
            trigger["load-type"] = [load]
        }
        
        if let doms = domains, !doms.isEmpty {
            trigger["if-domain"] = doms.map { "*" + $0 }
        }
        
        if let unless = unlessDomains, !unless.isEmpty {
            trigger["unless-domain"] = unless
        }
        
        let action: [String: Any] = ["type": "block"]
        
        return [
            "trigger": trigger,
            "action": action
        ]
    }
    
    private func parseExceptionRule(_ line: String) -> [String: Any]? {
        let rule = String(line.dropFirst(2))
        
        var urlFilter = rule
        var domains: [String]? = nil
        
        if let domainIndex = rule.range(of: "$domain=") {
            let domainPart = String(rule[domainIndex.upperBound...])
            let components = domainPart.components(separatedBy: "$")
            let domainString = components[0]
            
            domains = domainString.components(separatedBy: ",")
            
            urlFilter = String(rule[..<domainIndex.lowerBound])
            urlFilter = urlFilter.replacingOccurrences(of: "$", with: "")
        }
        
        let urlFilterRegex = convertToRegex(urlFilter)
        
        var trigger: [String: Any] = ["url-filter": urlFilterRegex]
        
        if let doms = domains, !doms.isEmpty {
            trigger["if-domain"] = doms.map { "*" + $0 }
        }
        
        let action: [String: Any] = ["type": "ignore-previous-rules"]
        
        return [
            "trigger": trigger,
            "action": action
        ]
    }
    
    private func parseCSSHideRule(_ line: String) -> [String: Any]? {
        let parts = line.components(separatedBy: "##")
        guard parts.count == 2 else { return nil }
        
        let domains = parts[0]
        let selector = parts[1]
        
        guard !selector.isEmpty else { return nil }
        
        var trigger: [String: Any] = ["url-filter": ".*"]
        
        if !domains.isEmpty {
            let domainList = domains.components(separatedBy: ",").map { "*" + $0.trimmingCharacters(in: .whitespaces) }
            trigger["if-domain"] = domainList
        }
        
        let action: [String: Any] = [
            "type": "css-display-none",
            "selector": selector
        ]
        
        return [
            "trigger": trigger,
            "action": action
        ]
    }
    
    private func convertToRegex(_ pattern: String) -> String {
        var regex = pattern
        
        regex = regex.replacingOccurrences(of: ".", with: "\\.")
        regex = regex.replacingOccurrences(of: "*", with: ".*")
        regex = regex.replacingOccurrences(of: "+", with: "\\+")
        regex = regex.replacingOccurrences(of: "?", with: "\\?")
        regex = regex.replacingOccurrences(of: "(", with: "\\(")
        regex = regex.replacingOccurrences(of: ")", with: "\\)")
        regex = regex.replacingOccurrences(of: "[", with: "\\[")
        regex = regex.replacingOccurrences(of: "]", with: "\\]")
        
        return regex
    }
    
    private func escapeDomain(_ domain: String) -> String {
        var escaped = domain
        escaped = escaped.replacingOccurrences(of: ".", with: "\\.")
        return escaped
    }
}
